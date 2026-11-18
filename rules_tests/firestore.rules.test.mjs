import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  setLogLevel,
  Timestamp,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const endpoint = process.env.FIRESTORE_EMULATOR_HOST;
if (!endpoint || !/^(localhost|127\.0\.0\.1|\[::1\]):\d+$/.test(endpoint)) {
  throw new Error('Run through npm run test:emulator with a local Firestore emulator.');
}

const separator = endpoint.lastIndexOf(':');
const host = endpoint.slice(0, separator).replace(/^\[|\]$/g, '');
const port = Number(endpoint.slice(separator + 1));
const at = Timestamp.fromDate(new Date('2026-11-17T10:00:00Z'));
let environment;
setLogLevel('silent');

function client(uid = 'alice') {
  return uid === null
    ? environment.unauthenticatedContext().firestore()
    : environment.authenticatedContext(uid, {
        email: `${uid}@example.com`,
        email_verified: false,
      }).firestore();
}

function report(overrides = {}) {
  return {
    passengerId: 'alice',
    corridorId: 'kacyiru_kimironko',
    price: 1000,
    timeSegment: 'morning',
    weather: 'clear',
    status: 'pending',
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

function cashOut(overrides = {}) {
  return {
    passengerId: 'alice',
    amount: 50,
    method: 'MTN MoMo',
    status: 'pending',
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

function subscription(reference = 'NEW12345', overrides = {}) {
  return { passengerId: 'alice', reference, amount: 2000, status: 'pending', ...overrides };
}

async function seed(records) {
  await environment.withSecurityRulesDisabled(async (context) => {
    await Promise.all(Object.entries(records).map(([path, data]) =>
      setDoc(doc(context.firestore(), path), data)));
  });
}

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'demo-fairfare',
    firestore: {
      host,
      port,
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
}, { timeout: 30000 });

beforeEach(async () => {
  await environment.clearFirestore();
  const profile = (uid) => ({
    displayName: uid,
    email: `${uid}@example.com`,
    createdAt: at,
    trustScore: 15,
    streak: 1,
    badges: [],
    verifiedCount: 3,
    lastReportDate: at,
  });
  const route = { fromArea: 'Kacyiru', toArea: 'Kimironko', label: 'Home', createdAt: at };
  const { passengerId, ...unowned } = report({ createdAt: at });
  await seed({
    'passengers/alice': profile('alice'),
    'passengers/bob': profile('bob'),
    'passengers/alice/savedRoutes/route_a': route,
    'passengers/bob/savedRoutes/route_b': route,
    'corridors/kacyiru_kimironko': { fromArea: 'Kacyiru', toArea: 'Kimironko', isSeeded: true, createdAt: at },
    'corridorStats/kacyiru_kimironko': { median: 1000, low: 800, high: 1200, sampleSize: 5, confidence: 'limited', windowDays: 14, updatedAt: at },
    'notarizations/stamp': { hash: 'abc', txId: 'testnet', periodStart: at, periodEnd: at, createdAt: at },
    'leaderboard/alice': { displayName: 'alice', trustScore: 15 },
    'poolLedger/main': { rewardBalance: 1000, operationsBalance: 500, reserveBalance: 200, updatedAt: at },
    'reports/pending_a': report({ createdAt: at, processedAt: at }),
    'reports/pending_b': report({ passengerId: 'bob', createdAt: at }),
    'reports/verified_a': report({ status: 'verified', createdAt: at, verifiedAt: at }),
    'reports/rejected_a': report({ status: 'rejected', createdAt: at, reason: 'Out of band' }),
    'reports/expired_a': report({ status: 'expired', createdAt: at }),
    'reports/seed': { ...unowned, status: 'verified', isSeeded: true, verifiedAt: at },
    'wallets/alice': { pendingBalance: 20, finalizedBalance: 100, updatedAt: at },
    'wallets/bob': { pendingBalance: 0, finalizedBalance: 200, updatedAt: at },
    'walletEntries/reward_a': { passengerId: 'alice', reportId: 'verified_a', amount: 50, state: 'pending', createdAt: at },
    'walletEntries/reward_b': { passengerId: 'bob', reportId: 'pending_b', amount: 50, state: 'pending', createdAt: at },
    'cashOutRequests/cash_a': cashOut({ createdAt: at }),
    'cashOutRequests/cash_b': cashOut({ passengerId: 'bob', createdAt: at }),
    'subscriptions/OLDREF1': subscription('OLDREF1', { status: 'active', startsAt: at, endsAt: at }),
    'subscriptions/BOBREF1': subscription('BOBREF1', { passengerId: 'bob' }),
    'subscriptions/REJECT1': subscription('REJECT1', { status: 'rejected' }),
    'internal/config': { secret: 'emulator-only' },
  });
});

after(async () => {
  await environment?.cleanup();
});

for (const path of ['corridors/kacyiru_kimironko', 'corridorStats/kacyiru_kimironko', 'notarizations/stamp', 'leaderboard/alice']) {
  test(`${path}: public reads and lists, no client writes`, async () => {
    const anonymous = client(null);
    await assertSucceeds(getDoc(doc(anonymous, path)));
    await assertSucceeds(getDocs(collection(anonymous, path.split('/')[0])));
    const ref = doc(client(), path);
    await assertFails(updateDoc(ref, { extra: true }));
    await assertFails(deleteDoc(ref));
    await assertFails(setDoc(doc(client(), `${path.split('/')[0]}/new`), { extra: true }));
    await assertFails(setDoc(doc(anonymous, `${path.split('/')[0]}/new`), { extra: true }));
  });
}

for (const path of ['passengers/alice', 'passengers/alice/savedRoutes/route_a', 'reports/pending_a', 'wallets/alice', 'walletEntries/reward_a', 'cashOutRequests/cash_a', 'subscriptions/OLDREF1']) {
  test(`${path}: only its owner can read`, async () => {
    await assertSucceeds(getDoc(doc(client(), path)));
    await assertFails(getDoc(doc(client('bob'), path)));
    await assertFails(getDoc(doc(client(null), path)));
  });
}

test('private profiles cannot be scanned for leaderboard data', async () => {
  await assertFails(getDocs(collection(client(), 'passengers')));
});

test('signup accepts only the authenticated passenger basic profile', async () => {
  const data = { displayName: 'New Passenger', email: 'new@example.com', createdAt: serverTimestamp() };
  await assertSucceeds(setDoc(doc(client('new'), 'passengers/new'), data));
  await assertFails(setDoc(doc(client('bob'), 'passengers/other'), data));
  await assertFails(setDoc(doc(client(null), 'passengers/anonymous'), data));
});

for (const [field, value] of Object.entries({ trustScore: 100, streak: 7, badges: ['Pioneer'], verifiedCount: 10, lastReportDate: Timestamp.fromMillis(at.toMillis() + 86400000), phone: '123', role: 'admin' })) {
  test(`signup cannot initialize ${field}`, async () => {
    await assertFails(setDoc(doc(client('new'), 'passengers/new'), {
      displayName: 'New Passenger', email: 'new@example.com', createdAt: serverTimestamp(), [field]: value,
    }));
  });
  test(`profile edits cannot change ${field}`, async () => {
    await assertFails(updateDoc(doc(client(), 'passengers/alice'), { [field]: value }));
  });
}

test('profile names can change without changing protected fields', async () => {
  await assertSucceeds(updateDoc(doc(client(), 'passengers/alice'), { displayName: 'New Name' }));
  assert.equal((await getDoc(doc(client(), 'passengers/alice'))).data().trustScore, 15);
  await assertFails(updateDoc(doc(client(), 'passengers/alice'), { email: 'other@example.com' }));
  await assertFails(deleteDoc(doc(client(), 'passengers/alice')));
});

test('signup rejects false email, blank name, missing fields, and forged timestamp', async () => {
  const ref = doc(client('new'), 'passengers/new');
  const valid = { displayName: 'New', email: 'new@example.com', createdAt: serverTimestamp() };
  for (const changes of [{ email: 'other@example.com' }, { displayName: '  ' }, { displayName: ' New ' }, { createdAt: at }]) {
    await assertFails(setDoc(ref, { ...valid, ...changes }));
  }
  await assertFails(setDoc(ref, { displayName: 'New' }));
});

test('saved routes support owner CRUD and reject other passengers', async () => {
  const path = 'passengers/alice/savedRoutes/new';
  const data = { fromArea: 'Kacyiru', toArea: 'Kimironko', label: 'Work', createdAt: serverTimestamp() };
  await assertSucceeds(setDoc(doc(client(), path), data));
  await assertSucceeds(getDocs(collection(client(), 'passengers/alice/savedRoutes')));
  await assertSucceeds(updateDoc(doc(client(), path), { label: 'Office', toArea: 'Remera' }));
  await assertFails(setDoc(doc(client('bob'), 'passengers/alice/savedRoutes/foreign'), data));
  await assertFails(updateDoc(doc(client('bob'), path), { label: 'Other' }));
  await assertFails(deleteDoc(doc(client('bob'), path)));
  await assertSucceeds(deleteDoc(doc(client(), path)));
});

test('saved routes reject invalid areas, blank labels, extra fields, and timestamp changes', async () => {
  const data = { fromArea: 'Kacyiru', toArea: 'Kimironko', label: 'Work', createdAt: serverTimestamp() };
  for (const changes of [{ fromArea: '' }, { toArea: 'KACYIRU' }, { label: ' ' }, { passengerId: 'alice' }, { createdAt: at }]) {
    await assertFails(setDoc(doc(client(), 'passengers/alice/savedRoutes/new'), { ...data, ...changes }));
  }
  await assertFails(updateDoc(doc(client(), 'passengers/alice/savedRoutes/route_a'), { createdAt: serverTimestamp() }));
});

for (const price of [1, 50000]) {
  test(`reports accept boundary price ${price}`, async () => {
    await assertSucceeds(setDoc(doc(client(), 'reports/new'), report({ price })));
  });
}

test('reports accept empty backend metadata at creation', async () => {
  await assertSucceeds(setDoc(doc(client(), 'reports/new'), report({
    processedAt: null, verifiedAt: null, reason: null, isSeeded: false,
  })));
});

for (const [field, value] of [
  ['passengerId', 'bob'], ['passengerId', null], ['price', 0], ['price', -1], ['price', 50001],
  ['price', 1.5], ['price', '1000'], ['corridorId', 'missing'], ['timeSegment', 'dawn'],
  ['weather', 'snow'], ['createdAt', at], ['isSeeded', true], ['processedAt', at],
  ['verifiedAt', at], ['reason', 'Approved'], ['status', 'verified'], ['status', 'rejected'],
  ['status', 'expired'], ['extra', true],
]) {
  test(`report creation rejects ${field}=${String(value)}`, async () => {
    await assertFails(setDoc(doc(client(), 'reports/new'), report({ [field]: value })));
  });
}

test('reports require authentication and all mandatory fields', async () => {
  await assertFails(setDoc(doc(client(null), 'reports/new'), report()));
  await assertFails(setDoc(doc(client(), 'reports/new'), { passengerId: 'alice', status: 'pending' }));
});

test('pending price edits preserve backend metadata', async () => {
  const ref = doc(client(), 'reports/pending_a');
  await assertSucceeds(updateDoc(ref, { price: 1200 }));
  assert.deepEqual((await getDoc(ref)).data().processedAt, at);
  await assertFails(updateDoc(doc(client('bob'), 'reports/pending_a'), { price: 1300 }));
  await assertFails(deleteDoc(doc(client('bob'), 'reports/pending_a')));
  await assertSucceeds(deleteDoc(ref));
});

for (const changes of [
  { price: 0 }, { price: 50001 }, { status: 'verified' }, { passengerId: 'bob' },
  { corridorId: 'other' }, { timeSegment: 'evening' }, { weather: 'heavyRain' },
  { createdAt: serverTimestamp() }, { processedAt: null }, { processedAt: deleteField() },
  { verifiedAt: at }, { isSeeded: true }, { reason: 'Verified' },
]) {
  test(`pending edits reject changes to ${Object.keys(changes).join(',')}`, async () => {
    await assertFails(updateDoc(doc(client(), 'reports/pending_a'), changes));
  });
}

for (const status of ['verified', 'rejected', 'expired']) {
  test(`${status} reports are read-only for passengers`, async () => {
    const ref = doc(client(), `reports/${status}_a`);
    await assertFails(updateDoc(ref, { price: 1200 }));
    await assertFails(deleteDoc(ref));
  });
}

test('seed reports have no owner, stay private, and cannot be created by clients', async () => {
  const { passengerId, ...data } = report({ status: 'verified', isSeeded: true, verifiedAt: at });
  await assertFails(setDoc(doc(client(), 'reports/new_seed'), data));
  await assertFails(getDoc(doc(client(), 'reports/seed')));
  await assertFails(updateDoc(doc(client(), 'reports/seed'), { price: 1 }));
  await assertFails(deleteDoc(doc(client(), 'reports/seed')));
  await environment.withSecurityRulesDisabled(async (context) => {
    assert.equal(Object.hasOwn((await getDoc(doc(context.firestore(), 'reports/seed'))).data(), 'passengerId'), false);
  });
});

for (const name of ['reports', 'walletEntries', 'cashOutRequests', 'subscriptions']) {
  test(`${name}: owner-filtered lists succeed, unfiltered scans fail`, async () => {
    const db = client();
    await assertSucceeds(getDocs(query(collection(db, name), where('passengerId', '==', 'alice'))));
    await assertFails(getDocs(collection(db, name)));
    await assertFails(getDocs(query(collection(db, name), where('passengerId', '==', 'bob'))));
  });
}

for (const path of ['wallets/alice', 'walletEntries/reward_a', 'poolLedger/main']) {
  test(`${path}: client accounting writes are blocked`, async () => {
    const ref = doc(client(), path);
    await assertFails(updateDoc(ref, { amount: 999999 }));
    await assertFails(deleteDoc(ref));
    await assertFails(setDoc(doc(client(), `${path.split('/')[0]}/new`), { passengerId: 'alice', amount: 100 }));
  });
}

test('pool ledger and unknown collections are private even to signed-in passengers', async () => {
  for (const path of ['poolLedger/main', 'internal/config', 'passengers/alice/private/anything']) {
    await assertFails(getDoc(doc(client(), path)));
    await assertFails(getDoc(doc(client(null), path)));
    await assertFails(setDoc(doc(client(), path), { value: 'new' }));
  }
});

for (const method of ['MTN MoMo', 'Airtel Money']) {
  test(`cash-out accepts ${method} up to the finalized balance`, async () => {
    await assertSucceeds(setDoc(doc(client(), 'cashOutRequests/new'), cashOut({ method, amount: 100 })));
  });
}

for (const changes of [
  { amount: 0 }, { amount: -1 }, { amount: 101 }, { amount: 1.5 }, { amount: '50' },
  { passengerId: 'bob' }, { method: 'cash' }, { status: 'paid' }, { createdAt: at }, { extra: true },
]) {
  test(`cash-out rejects ${JSON.stringify(changes)}`, async () => {
    await assertFails(setDoc(doc(client(), 'cashOutRequests/new'), cashOut(changes)));
  });
}

test('cash-out needs authentication, a wallet, required fields, and server-only approval', async () => {
  await assertFails(setDoc(doc(client(null), 'cashOutRequests/new'), cashOut()));
  await assertFails(setDoc(doc(client('new'), 'cashOutRequests/new'), cashOut({ passengerId: 'new' })));
  await assertFails(setDoc(doc(client(), 'cashOutRequests/new'), { passengerId: 'alice' }));
  await assertFails(updateDoc(doc(client(), 'cashOutRequests/cash_a'), { status: 'paid' }));
  await assertFails(updateDoc(doc(client(), 'cashOutRequests/cash_a'), { amount: 1 }));
  await assertFails(deleteDoc(doc(client(), 'cashOutRequests/cash_a')));
});

test('subscriptions accept a normalized reference, expected price, and empty dates', async () => {
  await assertSucceeds(setDoc(doc(client(), 'subscriptions/NEW12345'), subscription('NEW12345', { startsAt: null, endsAt: null })));
});

for (const reference of ['SHORT', 'A'.repeat(21), 'abc123', 'AB 123', 'ABC-123']) {
  test(`subscriptions reject reference ${reference}`, async () => {
    await assertFails(setDoc(doc(client(), `subscriptions/${reference}`), subscription(reference)));
  });
}

for (const changes of [
  { passengerId: 'bob' }, { reference: 'OTHER123' }, { amount: 1 }, { amount: '2000' },
  { status: 'active' }, { startsAt: at }, { endsAt: at }, { extra: true },
]) {
  test(`subscriptions reject ${JSON.stringify(changes)}`, async () => {
    await assertFails(setDoc(doc(client(), 'subscriptions/NEW12345'), subscription('NEW12345', changes)));
  });
}

test('subscription references cannot be overwritten or deleted, including rejected ones', async () => {
  for (const reference of ['OLDREF1', 'REJECT1']) {
    await assertFails(setDoc(doc(client(), `subscriptions/${reference}`), subscription(reference)));
    await assertFails(deleteDoc(doc(client(), `subscriptions/${reference}`)));
    await assertFails(setDoc(doc(client('bob'), `subscriptions/${reference}`), subscription(reference, { passengerId: 'bob' })));
  }
  await assertFails(setDoc(doc(client(null), 'subscriptions/NEW12345'), subscription()));
  await assertFails(setDoc(doc(client(), 'subscriptions/NEW12345'), { passengerId: 'alice' }));
});

test('an unauthorized accounting write rejects the entire batch', async () => {
  const db = client();
  const batch = writeBatch(db);
  batch.update(doc(db, 'passengers/alice'), { displayName: 'Changed' });
  batch.update(doc(db, 'wallets/alice'), { finalizedBalance: 99999 });
  await assertFails(batch.commit());
  assert.equal((await getDoc(doc(db, 'passengers/alice'))).data().displayName, 'alice');
});

test('trusted backend writes remain possible and owners can observe the results', async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await updateDoc(doc(context.firestore(), 'reports/pending_a'), { status: 'verified', verifiedAt: at, processedAt: at });
    await updateDoc(doc(context.firestore(), 'wallets/alice'), { finalizedBalance: 150 });
    await updateDoc(doc(context.firestore(), 'passengers/alice'), { trustScore: 20 });
    await updateDoc(doc(context.firestore(), 'leaderboard/alice'), { displayName: 'Updated', trustScore: 20 });
  });
  assert.equal((await getDoc(doc(client(), 'reports/pending_a'))).data().status, 'verified');
  assert.equal((await getDoc(doc(client(), 'wallets/alice'))).data().finalizedBalance, 150);
  assert.equal((await getDoc(doc(client(null), 'leaderboard/alice'))).data().displayName, 'Updated');
});
