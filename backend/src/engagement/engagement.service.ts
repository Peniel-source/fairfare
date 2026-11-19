import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { FirebaseService } from '../firebase/firebase.service.js';
import { COLLECTIONS } from '../firebase/firestore-paths.js';
import { REPORT_VERIFIED, type ReportVerifiedEvent } from '../events/report-events.js';
import { newBadges, nextStreak } from './engagement-rules.js';

// on each verified report, updates verifiedCount, the daily streak,
// lastReportDate and any newly earned badges on passengers/{uid}.
@Injectable()
export class EngagementService {
  private readonly logger = new Logger('EngagementService');

  constructor(private readonly firebase: FirebaseService) {}

  @OnEvent(REPORT_VERIFIED)
  async handleVerified(event: ReportVerifiedEvent) {
    const db = this.firebase.firestore;
    const ref = db.collection(COLLECTIONS.passengers).doc(event.passengerId);
    try {
      await db.runTransaction(async (tx) => {
        const passenger = await tx.get(ref);
        if (!passenger.exists) {
          this.logger.warn(`no passenger ${event.passengerId} for report ${event.reportId}`);
          return;
        }
        const last = passenger.get('lastReportDate');
        const lastDate = last instanceof Timestamp ? last.toDate() : null;
        const verifiedAt = new Date(event.verifiedAt);

        const streak = nextStreak(Number(passenger.get('streak') ?? 0), lastDate, verifiedAt);
        const verifiedCount = Number(passenger.get('verifiedCount') ?? 0) + 1;
        const earned = (passenger.get('badges') as string[] | undefined) ?? [];
        const badges = newBadges(earned, {
          streak,
          verifiedCount,
          isFirstOnCorridor: event.isFirstOnCorridor,
        });

        tx.update(ref, {
          streak,
          verifiedCount,
          lastReportDate: Timestamp.fromDate(verifiedAt),
          ...(badges.length > 0 && { badges: FieldValue.arrayUnion(...badges) }),
        });
      });
    } catch (err) {
      this.logger.error(`engagement update failed for report ${event.reportId}`, err);
    }
  }
}
