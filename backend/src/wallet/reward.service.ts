import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OnEvent } from '@nestjs/event-emitter';
import {
  DocumentReference,
  FieldValue,
  Timestamp,
} from 'firebase-admin/firestore';
import { FirebaseService } from '../firebase/firebase.service.js';
import {
  COLLECTIONS,
  POOL_LEDGER_DOC_ID,
} from '../firebase/firestore-paths.js';
import {
  REPORT_VERIFIED,
  type ReportVerifiedEvent,
} from '../events/report-events.js';
import {
  holdCutoff,
  readRewardConfig,
  rewardFormula,
  type RewardConfig,
} from './reward-formula.js';

// How many due rewards one sweep finalizes; the next sweep picks up the rest.
const SWEEP_BATCH = 200;

// D5 reward engine.
// On each verified report it pays a pending reward from the pool into the
// passenger's wallet. A timer then moves rewards whose hold is over from
// pending to finalized, which is what the passenger can cash out.
// Only this server writes wallets, walletEntries and the pool ledger.
@Injectable()
export class RewardService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger('RewardService');
  private readonly config: RewardConfig;
  private timer?: NodeJS.Timeout;
  private sweeping = false;

  constructor(
    private readonly firebase: FirebaseService,
    config: ConfigService,
  ) {
    this.config = readRewardConfig((key) => config.get<string>(key));
  }

  // Sweep once at start-up (rewards that finished their hold while the server
  // was off), then on a timer.
  onModuleInit() {
    this.logger.log(
      `rewards: ${this.config.expectedReports} expected reports, ` +
        `${this.config.holdMinutes} min hold, sweep every ${this.config.sweepIntervalMs} ms`,
    );
    void this.finalizeDue();
    this.timer = setInterval(
      () => void this.finalizeDue(),
      this.config.sweepIntervalMs,
    );
    // unref means the timer alone never keeps a script alive
    this.timer.unref();
  }

  onModuleDestroy() {
    clearInterval(this.timer);
  }

  @OnEvent(REPORT_VERIFIED)
  async handleVerified(event: ReportVerifiedEvent) {
    try {
      await this.creditReward(event);
    } catch (err) {
      this.logger.error(`reward failed for report ${event.reportId}`, err);
    }
  }

  /**
   * Pays the reward for one verified report, in one transaction, and returns
   * the points paid (0 when nothing was paid).
   *
   * The entry id is the report id, so the same event arriving twice can
   * never pay twice. The pool is read inside the transaction, so two rewards
   * at the same moment can never take the pool below zero.
   */
  async creditReward(event: ReportVerifiedEvent): Promise<number> {
    const db = this.firebase.firestore;
    const entryRef = db
      .collection(COLLECTIONS.walletEntries)
      .doc(event.reportId);
    const walletRef = db.collection(COLLECTIONS.wallets).doc(event.passengerId);
    const ledgerRef = db
      .collection(COLLECTIONS.poolLedger)
      .doc(POOL_LEDGER_DOC_ID);

    const amount = await db.runTransaction(async (tx) => {
      const entry = await tx.get(entryRef);
      if (entry.exists) return 0;
      const ledger = await tx.get(ledgerRef);
      const pool = Number(ledger.get('rewardBalance') ?? 0);
      const reward = rewardFormula(
        pool,
        this.config.expectedReports,
        event.isFirstOnCorridor,
      );
      if (reward <= 0) return 0;

      const now = FieldValue.serverTimestamp();
      tx.create(entryRef, {
        passengerId: event.passengerId,
        reportId: event.reportId,
        amount: reward,
        state: 'pending',
        createdAt: now,
      });
      tx.set(
        walletRef,
        {
          pendingBalance: FieldValue.increment(reward),
          // Adding 0 makes sure the field exists on a brand new wallet.
          finalizedBalance: FieldValue.increment(0),
          updatedAt: now,
        },
        { merge: true },
      );
      tx.set(
        ledgerRef,
        { rewardBalance: FieldValue.increment(-reward), updatedAt: now },
        { merge: true },
      );
      return reward;
    });

    if (amount > 0) {
      this.logger.log(
        `paid ${amount} pending points for report ${event.reportId}`,
      );
    } else {
      this.logger.log(
        `no reward for report ${event.reportId} (already paid or pool empty)`,
      );
    }
    return amount;
  }

  /**
   * Moves every pending reward whose hold is over to finalized, and returns
   * how many it moved. Never runs two sweeps at once.
   */
  async finalizeDue(now = new Date()): Promise<number> {
    if (this.sweeping) return 0;
    this.sweeping = true;
    try {
      const cutoff = Timestamp.fromDate(
        holdCutoff(now, this.config.holdMinutes),
      );
      const due = await this.firebase.firestore
        .collection(COLLECTIONS.walletEntries)
        .where('state', '==', 'pending')
        .where('createdAt', '<=', cutoff)
        .orderBy('createdAt')
        .limit(SWEEP_BATCH)
        .get();

      let finalized = 0;
      for (const doc of due.docs) {
        try {
          if (await this.finalizeEntry(doc.ref)) finalized++;
        } catch (err) {
          this.logger.error(`could not finalize reward ${doc.id}`, err);
        }
      }
      if (finalized > 0) this.logger.log(`finalized ${finalized} rewards`);
      return finalized;
    } catch (err) {
      this.logger.error('reward sweep failed', err);
      return 0;
    } finally {
      this.sweeping = false;
    }
  }

  // Re-reads the entry inside the transaction, so a reward finalized by an
  // earlier sweep is never moved twice.
  private async finalizeEntry(entryRef: DocumentReference): Promise<boolean> {
    const db = this.firebase.firestore;
    return db.runTransaction(async (tx) => {
      const entry = await tx.get(entryRef);
      if (!entry.exists || entry.get('state') !== 'pending') return false;
      const amount = Number(entry.get('amount'));
      const passengerId = entry.get('passengerId');
      if (
        !Number.isInteger(amount) ||
        amount <= 0 ||
        typeof passengerId !== 'string'
      ) {
        this.logger.warn(`skipping malformed reward ${entryRef.id}`);
        return false;
      }
      tx.update(entryRef, { state: 'finalized' });
      tx.set(
        db.collection(COLLECTIONS.wallets).doc(passengerId),
        {
          pendingBalance: FieldValue.increment(-amount),
          finalizedBalance: FieldValue.increment(amount),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return true;
    });
  }
}
