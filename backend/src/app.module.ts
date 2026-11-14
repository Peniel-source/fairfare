import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { createObserveModule } from '@nestjs/observe';
import { AppController } from './app.controller.js';
import { ReportsModule } from './reports/reports.module.js';
import { CorridorsModule } from './corridors/corridors.module.js';
import { WalletModule } from './wallet/wallet.module.js';
import { TrustModule } from './trust/trust.module.js';
import { EngagementModule } from './engagement/engagement.module.js';
import { PaymentsModule } from './payments/payments.module.js';
import { FirebaseModule } from './firebase/firebase.module.js';

export const { ObserveModule, ObserveInstrument } = createObserveModule();

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    EventEmitterModule.forRoot(),
    FirebaseModule,
    ReportsModule,
    CorridorsModule,
    WalletModule,
    TrustModule,
    EngagementModule,
    PaymentsModule,
  ],
  controllers: [AppController],
})
export class AppModule {}