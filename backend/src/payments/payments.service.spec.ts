import { ConflictException, NotFoundException } from '@nestjs/common';
import { describe, expect, it } from 'vitest';
import type { FirebaseService } from '../firebase/firebase.service.js';
import { PaymentsService } from './payments.service.js';

// Minimal in-memory stand-in for the Firestore calls PaymentsService makes.
function fakeFirebase(sub?: Record<string, unknown>) {
  const writes: { op: string; data: Record<string, unknown> }[] = [];
  const doc = (path: string) => ({ path });
  const tx = {
    get: async () => ({
      exists: sub !== undefined,
      get: (field: string) => sub?.[field],
    }),
    update: (_ref: unknown, data: Record<string, unknown>) => writes.push({ op: 'update', data }),
    set: (_ref: unknown, data: Record<string, unknown>) => writes.push({ op: 'set', data }),
  };
  const firestore = {
    collection: (name: string) => ({
      doc: (id: string) => doc(`${name}/${id}`),
    }),
    runTransaction: async (fn: (t: typeof tx) => Promise<void>) => fn(tx),
  };
  return { service: { firestore } as unknown as FirebaseService, writes };
}

describe('PaymentsService.approve', () => {
  it('activates a pending Pass paid at the Pass price', async () => {
    const { service, writes } = fakeFirebase({
      status: 'pending',
      amount: 2000,
    });
    const result = await new PaymentsService(service).approve(
      'ABC123',
      new Date('2026-11-01T00:00:00Z'),
    );
    expect(result.status).toBe('active');
    expect(result.endsAt).toBe('2026-12-01T00:00:00.000Z');
    expect(writes.map((w) => w.op)).toEqual(['update', 'set']);
  });

  it('refuses an amount other than the Pass price and writes nothing', async () => {
    const { service, writes } = fakeFirebase({
      status: 'pending',
      amount: 1_000_000,
    });
    await expect(new PaymentsService(service).approve('ABC123')).rejects.toThrow(ConflictException);
    expect(writes).toEqual([]);
  });

  it('refuses a reference that is not pending or does not exist', async () => {
    const active = fakeFirebase({ status: 'active', amount: 2000 });
    await expect(new PaymentsService(active.service).approve('ABC123')).rejects.toThrow(
      ConflictException,
    );
    const missing = fakeFirebase();
    await expect(new PaymentsService(missing.service).approve('ABC123')).rejects.toThrow(
      NotFoundException,
    );
  });
});

describe('PaymentsService.listPending', () => {
  it('lists pending payments with the passenger email and name', async () => {
    const pendingDoc = {
      id: 'ABC123',
      get: (f: string) => ({ passengerId: 'p1', amount: 2000 })[f],
    };
    const passenger = {
      id: 'p1',
      exists: true,
      get: (f: string) => ({ email: 'a@x.rw', displayName: 'Aline' })[f],
    };
    const firestore = {
      collection: () => ({
        where: () => ({
          limit: () => ({ get: async () => ({ empty: false, docs: [pendingDoc] }) }),
        }),
        doc: (id: string) => ({ id }),
      }),
      getAll: async () => [passenger],
    };
    const rows = await new PaymentsService({
      firestore,
    } as unknown as FirebaseService).listPending();
    expect(rows).toEqual([
      {
        reference: 'ABC123',
        amount: 2000,
        passengerId: 'p1',
        email: 'a@x.rw',
        displayName: 'Aline',
      },
    ]);
  });
});
