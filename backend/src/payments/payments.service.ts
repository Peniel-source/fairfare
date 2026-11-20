import {
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { FirebaseService } from '../firebase/firebase.service.js';
import { COLLECTIONS, POOL_LEDGER_DOC_ID } from '../firebase/firestore-paths.js';
import { PASS_PRICE_RWF, passEnd, splitPayment } from './pool-split.js';

export type PendingPayment = {
  reference: string;
  amount: number;
  passengerId: string;
  // So the admin can match the payer on the MoMo statement to the account.
  email: string | null;
  displayName: string | null;
};

export type SubscriptionResult = {
  reference: string;
  status: 'active' | 'rejected';
  startsAt?: string;
  endsAt?: string;
};

// E3: approves or rejects a pending Pass payment (subscriptions/{reference}).
// Approval activates a 30-day Pass and adds the 35/45/20 split to poolLedger/main.
@Injectable()
export class PaymentsService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger('PaymentsService');
  private unsubscribe?: () => void;

  constructor(private readonly firebase: FirebaseService) {}

  // Development only: PAYMENTS_AUTO_APPROVE=true approves every pending
  // subscription, and only when connected to the emulator.
  onModuleInit() {
    if (process.env.PAYMENTS_AUTO_APPROVE !== 'true') return;
    if (!process.env.FIRESTORE_EMULATOR_HOST) {
      this.logger.warn('PAYMENTS_AUTO_APPROVE ignored: not running on the emulator');
      return;
    }
    this.logger.log('auto-approving pending subscriptions (emulator)');
    this.unsubscribe = this.firebase.firestore
      .collection(COLLECTIONS.subscriptions)
      .where('status', '==', 'pending')
      .onSnapshot(
        (snap) => {
          for (const change of snap.docChanges()) {
            if (change.type !== 'added') continue;
            this.approve(change.doc.id).catch((err) =>
              this.logger.error(`auto-approve failed for ${change.doc.id}`, err),
            );
          }
        },
        (err) => this.logger.error('subscription listener failed', err),
      );
  }

  onModuleDestroy() {
    this.unsubscribe?.();
  }

  async approve(reference: string, now = new Date()): Promise<SubscriptionResult> {
    const db = this.firebase.firestore;
    const subRef = db.collection(COLLECTIONS.subscriptions).doc(reference);
    const ledgerRef = db.collection(COLLECTIONS.poolLedger).doc(POOL_LEDGER_DOC_ID);
    const endsAt = passEnd(now);

    await db.runTransaction(async (tx) => {
      const sub = await tx.get(subRef);
      this.assertPending(reference, sub.exists, sub.get('status'));

      // Never trust the amount on the document: only the Pass price can be
      // approved, so a tampered amount cannot inflate the pool ledger.
      const amount = sub.get('amount');
      if (amount !== PASS_PRICE_RWF) {
        throw new ConflictException(
          `subscription ${reference} has amount ${String(amount)}, expected ${PASS_PRICE_RWF}`,
        );
      }
      const split = splitPayment(amount);
      tx.update(subRef, {
        status: 'active',
        startsAt: Timestamp.fromDate(now),
        endsAt: Timestamp.fromDate(endsAt),
      });
      tx.set(
        ledgerRef,
        {
          rewardBalance: FieldValue.increment(split.rewardBalance),
          operationsBalance: FieldValue.increment(split.operationsBalance),
          reserveBalance: FieldValue.increment(split.reserveBalance),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    });

    this.logger.log(`approved subscription ${reference}`);
    return {
      reference,
      status: 'active',
      startsAt: now.toISOString(),
      endsAt: endsAt.toISOString(),
    };
  }

  // Pending payments for the admin to check against the MoMo statement.
  async listPending(limit = 100): Promise<PendingPayment[]> {
    const db = this.firebase.firestore;
    const snap = await db
      .collection(COLLECTIONS.subscriptions)
      .where('status', '==', 'pending')
      .limit(limit)
      .get();
    if (snap.empty) return [];

    const passengerIds = [...new Set(snap.docs.map((d) => String(d.get('passengerId'))))];
    const passengers = await db.getAll(
      ...passengerIds.map((id) => db.collection(COLLECTIONS.passengers).doc(id)),
    );
    const byId = new Map(passengers.map((p) => [p.id, p]));

    return snap.docs.map((doc) => {
      const passengerId = String(doc.get('passengerId'));
      const passenger = byId.get(passengerId);
      return {
        reference: doc.id,
        amount: Number(doc.get('amount')),
        passengerId,
        email: passenger?.exists ? (passenger.get('email') ?? null) : null,
        displayName: passenger?.exists ? (passenger.get('displayName') ?? null) : null,
      };
    });
  }

  async reject(reference: string): Promise<SubscriptionResult> {
    const db = this.firebase.firestore;
    const subRef = db.collection(COLLECTIONS.subscriptions).doc(reference);

    await db.runTransaction(async (tx) => {
      const sub = await tx.get(subRef);
      this.assertPending(reference, sub.exists, sub.get('status'));
      tx.update(subRef, { status: 'rejected' });
    });

    this.logger.log(`rejected subscription ${reference}`);
    return { reference, status: 'rejected' };
  }

  private assertPending(reference: string, exists: boolean, status: unknown) {
    if (!exists) throw new NotFoundException(`no subscription ${reference}`);
    if (status !== 'pending') {
      throw new ConflictException(`subscription ${reference} is ${String(status)}, not pending`);
    }
  }
}
