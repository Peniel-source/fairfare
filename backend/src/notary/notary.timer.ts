//checks every 10 minutes and notarizes once a day, late in the evening
import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NotaryService } from './notary.service.js';

const CHECK_EVERY_MS = 10 * 60 * 1000;
const SEND_FROM_HOUR = 23;

@Injectable()
export class NotaryTimer implements OnModuleInit, OnModuleDestroy {
  private readonly log = new Logger('NotaryTimer');
  private timer?: NodeJS.Timeout;
  private busy = false;

  constructor(
    private readonly notary: NotaryService,
    private readonly config: ConfigService,
  ) {}

  //the timer only starts when NOTARY_DAILY=true is in .env
  onModuleInit() {
    if (this.config.get<string>('NOTARY_DAILY') !== 'true') return;
    this.log.log('daily notary is on, checking every 10 minutes');
    this.timer = setInterval(() => void this.check(), CHECK_EVERY_MS);
    //unref means the timer alone never keeps a script alive
    this.timer.unref();
  }

  onModuleDestroy() {
    clearInterval(this.timer);
  }

  //the hour in Kigali, 0 to 23
  hourInKigali(): number {
    const text = new Intl.DateTimeFormat('en-GB', {
      timeZone: 'Africa/Kigali',
      hour: '2-digit',
      hourCycle: 'h23',
    }).format(new Date());
    return Number(text);
  }

  async check() {
    //do not start a second check while one is still running
    if (this.busy) return;
    this.busy = true;
    try {
      if (this.hourInKigali() < SEND_FROM_HOUR) return;
      if (await this.notary.alreadyDoneToday()) return;
      const result = await this.notary.notarize();
      this.log.log('notarized ' + result.date + ' tx ' + result.txHash);
    } catch (error) {
      this.log.error('notary check failed: ' + String(error));
    } finally {
      this.busy = false;
    }
  }
}