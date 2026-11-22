import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  DocumentSnapshot,
  Timestamp,
  type DocumentData,
  type Transaction,
} from 'firebase-admin/firestore';
import { FirebaseService } from '../firebase/firebase.service.js';
import { COLLECTIONS } from '../firebase/firestore-paths.js';
import {
  REPORT_REJECTED,
  REPORT_VERIFIED,
  type ReportRejectedEvent,
  type ReportVerifiedEvent,
} from '../events/report-events.js';
import { bandCheck, type CorridorBand } from './band-check.js';
import {
  findMatch,
  MATCH_WINDOW_MS,
  type MatchReport,
} from './corroboration.js';

const EXPIRED_REASON = 'No matching report within 48 hours';

type Outcome =
  | { type: 'verified'; event: ReportVerifiedEvent }
  | { type: 'rejected'; event: ReportRejectedEvent };

// Firestore report to the fields the matching needs
export function toMatchReport(
  doc: DocumentSnapshot<DocumentData>,
): MatchReport {
  const createdAt = doc.get('createdAt');
  return {
    id: doc.id,
    passengerId: doc.get('passengerId') ?? undefined,
    corridorId: doc.get('corridorId'),
    price: Number(doc.get('price')),
    timeSegment: doc.get('timeSegment'),
    status: doc.get('status'),
    createdAt:
      createdAt instanceof Timestamp ? createdAt.toDate() : new Date(0),
    isSeeded: doc.get('isSeeded') === true,
  };
}

@Injectable()
export class ReportsService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger('ReportsService');
  private unsubscribe?: () => void;
  private sweepTimer?: NodeJS.Timeout;
  // One report at a time so two matching reports don't race
  private queue: Promise<void> = Promise.resolve();

  constructor(
    private readonly firebase: FirebaseService,
    private readonly events: EventEmitter2,
  ) {}

  private get reports() {
    return this.firebase.firestore.collection(COLLECTIONS.reports);
  }

  onModuleInit() {
    if (process.env.VERIFY_ENGINE === 'off') return;

    // The first snapshot also picks up reports missed while the server was off
    this.unsubscribe = this.reports.where('status', '==', 'pending').onSnapshot(
      (snap) => {
        for (const change of snap.docChanges()) {
          if (change.type !== 'added') continue;
          if (change.doc.get('processedAt')) continue;
          this.enqueue(change.doc.id);
        }
      },
      (err) => this.logger.error('pending report listener failed', err),
    );

    const every = Number(process.env.REPORT_SWEEP_MS ?? 15 * 60 * 1000);
    this.sweepTimer = setInterval(() => void this.expireOldReports(), every);
    this.sweepTimer.unref();
    void this.expireOldReports();
  }

  onModuleDestroy() {
    this.unsubscribe?.();
    clearInterval(this.sweepTimer);
  }

  private enqueue(reportId: string) {
    this.queue = this.queue
      .then(() => this.processReport(reportId))
      .catch((err) => this.logger.error(`could not process ${reportId}`, err));
  }

  // Band check, then look for a match, then announce the result
  async processReport(reportId: string) {
    const outcomes = await this.firebase.firestore.runTransaction((tx) =>
      this.decide(tx, reportId),
    );
    for (const outcome of outcomes) {
      if (outcome.type === 'verified') {
        this.events.emit(REPORT_VERIFIED, outcome.event);
      } else {
        this.events.emit(REPORT_REJECTED, outcome.event);
      }
    }
  }

  private async decide(tx: Transaction, reportId: string): Promise<Outcome[]> {
    const db = this.firebase.firestore;
    const ref = this.reports.doc(reportId);
    const snap = await tx.get(ref);
    // Already handled, deleted, or a seed report
    if (!snap.exists || snap.get('status') !== 'pending') return [];
    if (snap.get('processedAt') || snap.get('isSeeded') === true) return [];

    const report = toMatchReport(snap);
    if (!report.passengerId) return [];

    const statsSnap = await tx.get(
      db.collection(COLLECTIONS.corridorStats).doc(report.corridorId),
    );
    const corridor: CorridorBand | null = statsSnap.exists
      ? {
          median: Number(statsSnap.get('median')),
          sampleSize: Number(statsSnap.get('sampleSize')),
        }
      : null;

    const now = Timestamp.now();
    const band = bandCheck(
      report.price,
      corridor,
      report.timeSegment,
      snap.get('weather'),
    );
    if (!band.ok) {
      tx.update(ref, {
        status: 'rejected',
        reason: band.reason,
        processedAt: now,
      });
      return [
        {
          type: 'rejected',
          event: {
            reportId,
            passengerId: report.passengerId,
            reason: band.reason,
          },
        },
      ];
    }

    const since = Timestamp.fromMillis(
      report.createdAt.getTime() - MATCH_WINDOW_MS,
    );
    const candidates = await tx.get(
      this.reports
        .where('corridorId', '==', report.corridorId)
        .where('status', '==', 'pending')
        .where('timeSegment', '==', report.timeSegment)
        .where('createdAt', '>=', since),
    );
    const match = findMatch(report, candidates.docs.map(toMatchReport));
    if (!match) {
      tx.update(ref, { processedAt: now });
      return [];
    }

    // Seed reports don't count, so a passenger can still be first
    const verified = await tx.get(
      this.reports
        .where('corridorId', '==', report.corridorId)
        .where('status', '==', 'verified')
        .limit(20),
    );
    const isFirstOnCorridor = verified.docs.every(
      (doc) => doc.get('isSeeded') === true,
    );

    const update = { status: 'verified', verifiedAt: now, processedAt: now };
    tx.update(this.reports.doc(match.id), update);
    tx.update(ref, update);

    const verifiedAt = now.toDate();
    // The older report gets the first on corridor credit
    return [
      {
        type: 'verified',
        event: {
          reportId: match.id,
          passengerId: match.passengerId!,
          corridorId: match.corridorId,
          price: match.price,
          isFirstOnCorridor,
          verifiedAt,
        },
      },
      {
        type: 'verified',
        event: {
          reportId,
          passengerId: report.passengerId,
          corridorId: report.corridorId,
          price: report.price,
          isFirstOnCorridor: false,
          verifiedAt,
        },
      },
    ];
  }

  // Pending reports past the 48 hour window expire, no reward and no penalty
  async expireOldReports() {
    try {
      const cutoff = Timestamp.fromMillis(Date.now() - MATCH_WINDOW_MS);
      const old = await this.reports
        .where('status', '==', 'pending')
        .where('createdAt', '<', cutoff)
        .limit(400)
        .get();
      if (old.empty) return;

      const batch = this.firebase.firestore.batch();
      const now = Timestamp.now();
      for (const doc of old.docs) {
        batch.update(doc.ref, {
          status: 'expired',
          reason: EXPIRED_REASON,
          processedAt: now,
        });
      }
      await batch.commit();
      this.logger.log(`expired ${old.size} reports`);
    } catch (err) {
      this.logger.error('expiry sweep failed', err);
    }
  }
}
