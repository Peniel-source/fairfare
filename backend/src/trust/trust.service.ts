import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { FieldValue } from 'firebase-admin/firestore';
import { FirebaseService } from '../firebase/firebase.service.js';
import { COLLECTIONS } from '../firebase/firestore-paths.js';
import {
  REPORT_REJECTED,
  REPORT_VERIFIED,
  type ReportRejectedEvent,
  type ReportVerifiedEvent,
} from '../events/report-events.js';
import { afterRejected, afterVerified, publicAvatar } from './trust-rules.js';

// E5: moves the trust score on verify/reject and keeps the public
// leaderboard/{uid} projection (displayName, avatar, trustScore) in sync.
@Injectable()
export class TrustService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger('TrustService');
  private unsubscribe?: () => void;

  constructor(private readonly firebase: FirebaseService) {}

  // Passengers can edit their name and avatar; the leaderboard copy is
  // backend-only.
  onModuleInit() {
    if (process.env.LEADERBOARD_SYNC === 'off') return;
    this.unsubscribe = this.firebase.firestore.collection(COLLECTIONS.passengers).onSnapshot(
      (snap) => {
        for (const change of snap.docChanges()) {
          if (change.type === 'removed') continue;
          const name = change.doc.get('displayName');
          if (typeof name !== 'string') continue;
          void this.syncLeaderboardProfile(
            change.doc.id,
            name,
            publicAvatar(change.doc.get('avatar')),
          );
        }
      },
      (err) => this.logger.error('passenger listener failed', err),
    );
  }

  onModuleDestroy() {
    this.unsubscribe?.();
  }

  @OnEvent(REPORT_VERIFIED)
  async handleVerified(event: ReportVerifiedEvent) {
    await this.applyScore(event.passengerId, afterVerified, event.reportId);
  }

  @OnEvent(REPORT_REJECTED)
  async handleRejected(event: ReportRejectedEvent) {
    await this.applyScore(event.passengerId, afterRejected, event.reportId);
  }

  private async applyScore(
    passengerId: string,
    next: (score: unknown) => number,
    reportId: string,
  ) {
    const db = this.firebase.firestore;
    const passengerRef = db.collection(COLLECTIONS.passengers).doc(passengerId);
    const boardRef = db.collection(COLLECTIONS.leaderboard).doc(passengerId);
    try {
      await db.runTransaction(async (tx) => {
        const passenger = await tx.get(passengerRef);
        if (!passenger.exists) {
          this.logger.warn(`no passenger ${passengerId} for report ${reportId}`);
          return;
        }
        const trustScore = next(passenger.get('trustScore'));
        tx.update(passengerRef, { trustScore });
        tx.set(
          boardRef,
          {
            displayName: passenger.get('displayName') ?? '',
            avatar: publicAvatar(passenger.get('avatar')) ?? FieldValue.delete(),
            trustScore,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      });
    } catch (err) {
      this.logger.error(`trust update failed for report ${reportId}`, err);
    }
  }

  private async syncLeaderboardProfile(
    passengerId: string,
    displayName: string,
    avatar: string | null,
  ) {
    const ref = this.firebase.firestore.collection(COLLECTIONS.leaderboard).doc(passengerId);
    try {
      const entry = await ref.get();
      // Only passengers who already have a score appear on the board.
      if (!entry.exists) return;
      if (entry.get('displayName') === displayName && (entry.get('avatar') ?? null) === avatar) {
        return;
      }
      await ref.update({
        displayName,
        avatar: avatar ?? FieldValue.delete(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (err) {
      this.logger.error(`leaderboard profile sync failed for ${passengerId}`, err);
    }
  }
}
