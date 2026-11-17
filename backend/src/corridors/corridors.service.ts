import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { FirebaseService } from '../firebase/firebase.service.js';
import { COLLECTIONS } from '../firebase/firestore-paths.js';
import { REPORT_VERIFIED, type ReportVerifiedEvent } from '../events/report-events.js';
import { computeStats, windowDays } from './stats.js';

@Injectable()
export class CorridorsService implements OnModuleInit, OnModuleDestroy {

  private logger = new Logger('CorridorsService'); //this logger to print messages in the terminal
  private timer?: NodeJS.Timeout; //use server as the timer

  //getting the Firebase connection here for read and write
  constructor(private firebase: FirebaseService) {}

  onModuleInit() {
    const every = Number(process.env.STATS_INTERVAL_MS ?? 10 * 60 * 1000);
    this.timer = setInterval(() => void this.updateAllCorridors(), every);
    this.timer.unref(); // lets the server close even if the timer is still running
  }

  //stop the timer if the server shuts down
  onModuleDestroy() {
    clearInterval(this.timer);
  }


  //if a new report is verified, refresh that corridor
  @OnEvent(REPORT_VERIFIED)
  async handleVerifiedReport(event: ReportVerifiedEvent) {
    try {
      await this.updateCorridorStats(event.corridorId);
    } catch (err) {
      this.logger.error('could not update stats for ' + event.corridorId, err);
    }
  }

  //now refresh every corridor
  async updateAllCorridors() {
    const db = this.firebase.firestore;
    const corridors = await db.collection(COLLECTIONS.corridors).select().get();

    for (const corridor of corridors.docs) {
      try {
        await this.updateCorridorStats(corridor.id);
      } catch (err) {
        this.logger.error('could not update stats for ' + corridor.id, err);
      }
    }
  }

  //work on prices for one corridir
  async updateCorridorStats(corridorId: string) {
    const db = this.firebase.firestore;
    const reports = db.collection(COLLECTIONS.reports);

    //still count the oldest date
    const oldestDate = Timestamp.fromMillis(Date.now() - windowDays * 24 * 60 * 60 * 1000);

    //get both verified and the seed reports
    const [recentSearch, seedSearch] = await Promise.all([
      reports
        .where('corridorId', '==', corridorId)
        .where('status', '==', 'verified')
        .where('createdAt', '>=', oldestDate)
        .get(),
      reports
        .where('corridorId', '==', corridorId)
        .where('status', '==', 'verified')
        .where('isSeeded', '==', true)
        .get(),
    ]);

    //put the prices in a map
    const priceById = new Map<string, number>();
    for (const doc of [...recentSearch.docs, ...seedSearch.docs]) {
      priceById.set(doc.id, doc.get('price'));
    }

    //pass the prices to the stats function to get new stats
    const stats = computeStats([...priceById.values()]);

    //error handling
    if (stats === null) return;

    //now save the result in corridorStats
    await db.collection(COLLECTIONS.corridorStats).doc(corridorId).set({
      ...stats,
      windowDays,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
}