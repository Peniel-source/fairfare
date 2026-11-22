import { Logger } from '@nestjs/common';
import type { ConfigService } from '@nestjs/config';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { ReportVerifiedEvent } from '../events/report-events.js';
import type { FirebaseService } from '../firebase/firebase.service.js';
import { RewardService } from './reward.service.js';

type Data = Record<string, unknown>;
type Write = { op: 'create' | 'set' | 'update'; path: string; data: Data };
type Filter = [field: string, op: string, value: unknown];

// Minimal in-memory stand-in for the Firestore calls RewardService makes.
// create and update change the stored documents, so a second call sees the
// first one's entry; every write is also recorded for the assertions.
function fakeFirebase(initial: Record<string, Data> = {}) {
  const docs = new Map<string, Data>(Object.entries(initial));
  const writes: Write[] = [];
  const ref = (path: string) => ({ path, id: path.split('/').pop() });
  const snapshot = (path: string) => {
    const data = docs.get(path);
    return {
      id: ref(path).id,
      ref: ref(path),
      exists: data !== undefined,
      get: (f: string) => data?.[f],
    };
  };
  const millis = (value: unknown) =>
    value instanceof Timestamp ? value.toMillis() : Number.NaN;
  const matches = (value: unknown, op: string, expected: unknown) =>
    op === '==' ? value === expected : millis(value) <= millis(expected);
  const query = (collection: string, filters: Filter[] = []): unknown => ({
    where: (field: string, op: string, value: unknown) =>
      query(collection, [...filters, [field, op, value]]),
    orderBy: () => query(collection, filters),
    limit: () => query(collection, filters),
    get: async () => ({
      docs: [...docs.keys()]
        .filter((path) => path.startsWith(`${collection}/`))
        .filter((path) =>
          filters.every(([f, op, v]) => matches(docs.get(path)?.[f], op, v)),
        )
        .map(snapshot),
    }),
  });
  const tx = {
    get: async (r: { path: string }) => snapshot(r.path),
    create: (r: { path: string }, data: Data) => {
      writes.push({ op: 'create', path: r.path, data });
      docs.set(r.path, data);
    },
    set: (r: { path: string }, data: Data) =>
      writes.push({ op: 'set', path: r.path, data }),
    update: (r: { path: string }, data: Data) => {
      writes.push({ op: 'update', path: r.path, data });
      docs.set(r.path, { ...docs.get(r.path), ...data });
    },
  };
  const firestore = {
    collection: (name: string) => ({
      doc: (id: string) => ref(`${name}/${id}`),
      ...(query(name) as object),
    }),
    runTransaction: async <T>(fn: (t: typeof tx) => Promise<T>) => fn(tx),
  };
  return {
    firebase: { firestore } as unknown as FirebaseService,
    writes,
    docs,
  };
}

const config = (env: Record<string, string> = {}) =>
  ({ get: (key: string) => env[key] }) as unknown as ConfigService;

const event = (
  overrides: Partial<ReportVerifiedEvent> = {},
): ReportVerifiedEvent => ({
  reportId: 'report-1',
  passengerId: 'alice',
  corridorId: 'kacyiru-kimironko',
  price: 1000,
  isFirstOnCorridor: true,
  verifiedAt: new Date('2026-11-22T10:00:00Z'),
  ...overrides,
});

const pool = (rewardBalance: number) => ({
  'poolLedger/main': { rewardBalance },
});

beforeEach(() => {
  // Keep the test output readable; the service logs every reward.
  vi.spyOn(Logger.prototype, 'log').mockImplementation(() => undefined);
  vi.spyOn(Logger.prototype, 'warn').mockImplementation(() => undefined);
  vi.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);
});

afterEach(() => {
  vi.restoreAllMocks();
});

describe('RewardService.creditReward', () => {
  it('pays a pending reward into the wallet and takes it from the pool', async () => {
    const { firebase, writes } = fakeFirebase(pool(700));

    const paid = await new RewardService(firebase, config()).creditReward(
      event(),
    );

    expect(paid).toBe(52);
    expect(writes).toEqual([
      {
        op: 'create',
        path: 'walletEntries/report-1',
        data: {
          passengerId: 'alice',
          reportId: 'report-1',
          amount: 52,
          state: 'pending',
          createdAt: FieldValue.serverTimestamp(),
        },
      },
      {
        op: 'set',
        path: 'wallets/alice',
        data: {
          pendingBalance: FieldValue.increment(52),
          finalizedBalance: FieldValue.increment(0),
          updatedAt: FieldValue.serverTimestamp(),
        },
      },
      {
        op: 'set',
        path: 'poolLedger/main',
        data: {
          rewardBalance: FieldValue.increment(-52),
          updatedAt: FieldValue.serverTimestamp(),
        },
      },
    ]);
  });

  it('pays less for a confirming report', async () => {
    const { firebase } = fakeFirebase(pool(700));
    const service = new RewardService(firebase, config());
    expect(
      await service.creditReward(event({ isFirstOnCorridor: false })),
    ).toBe(17);
  });

  it('uses REWARD_EXPECTED_REPORTS from the config', async () => {
    const { firebase } = fakeFirebase(pool(700));
    const service = new RewardService(
      firebase,
      config({ REWARD_EXPECTED_REPORTS: '7' }),
    );
    expect(await service.creditReward(event())).toBe(150);
  });

  it('never pays the same report twice', async () => {
    const { firebase, writes } = fakeFirebase(pool(700));
    const service = new RewardService(firebase, config());

    await service.creditReward(event());
    const second = await service.creditReward(event());

    expect(second).toBe(0);
    expect(writes.filter((w) => w.op === 'create')).toHaveLength(1);
  });

  it('writes nothing when the pool is empty or missing', async () => {
    const empty = fakeFirebase(pool(0));
    expect(
      await new RewardService(empty.firebase, config()).creditReward(event()),
    ).toBe(0);
    expect(empty.writes).toEqual([]);

    const missing = fakeFirebase();
    expect(
      await new RewardService(missing.firebase, config()).creditReward(event()),
    ).toBe(0);
    expect(missing.writes).toEqual([]);
  });

  it('handleVerified logs a failure instead of crashing the server', async () => {
    const firebase = {
      firestore: {
        collection: () => ({ doc: () => ({}) }),
        runTransaction: async () => {
          throw new Error('Firestore is down');
        },
      },
    } as unknown as FirebaseService;
    const service = new RewardService(firebase, config());
    const logged = vi
      .spyOn(Logger.prototype, 'error')
      .mockImplementation(() => undefined);

    await expect(service.handleVerified(event())).resolves.toBeUndefined();
    expect(logged).toHaveBeenCalledOnce();
  });
});

describe('RewardService.finalizeDue', () => {
  const now = new Date('2026-11-22T12:00:00Z');
  const hoursAgo = (hours: number) =>
    Timestamp.fromDate(new Date(now.getTime() - hours * 60 * 60 * 1000));
  const entry = (state: string, createdAt: Timestamp, amount = 52) => ({
    passengerId: 'alice',
    reportId: 'r',
    amount,
    state,
    createdAt,
  });

  it('finalizes only pending rewards whose 24 hour hold is over', async () => {
    const { firebase, writes, docs } = fakeFirebase({
      'walletEntries/old': entry('pending', hoursAgo(30)),
      'walletEntries/recent': entry('pending', hoursAgo(2), 17),
      'walletEntries/done': entry('finalized', hoursAgo(50)),
    });

    const count = await new RewardService(firebase, config()).finalizeDue(now);

    expect(count).toBe(1);
    expect(docs.get('walletEntries/old')?.state).toBe('finalized');
    expect(docs.get('walletEntries/recent')?.state).toBe('pending');
    expect(writes).toEqual([
      { op: 'update', path: 'walletEntries/old', data: { state: 'finalized' } },
      {
        op: 'set',
        path: 'wallets/alice',
        data: {
          pendingBalance: FieldValue.increment(-52),
          finalizedBalance: FieldValue.increment(52),
          updatedAt: FieldValue.serverTimestamp(),
        },
      },
    ]);
  });

  it('uses a short hold for the demo', async () => {
    const { firebase } = fakeFirebase({
      'walletEntries/recent': entry('pending', hoursAgo(0.1)),
    });
    const service = new RewardService(
      firebase,
      config({ REWARD_HOLD_MINUTES: '2' }),
    );
    expect(await service.finalizeDue(now)).toBe(1);
  });

  it('skips a malformed entry instead of corrupting the wallet', async () => {
    const { firebase, writes } = fakeFirebase({
      'walletEntries/bad': entry('pending', hoursAgo(30), -5),
    });
    expect(await new RewardService(firebase, config()).finalizeDue(now)).toBe(
      0,
    );
    expect(writes).toEqual([]);
  });

  it('a second sweep finds nothing left to move', async () => {
    const { firebase, writes } = fakeFirebase({
      'walletEntries/old': entry('pending', hoursAgo(30)),
    });
    const service = new RewardService(firebase, config());
    await service.finalizeDue(now);
    expect(await service.finalizeDue(now)).toBe(0);
    expect(writes.filter((w) => w.op === 'update')).toHaveLength(1);
  });
});
