import { Module } from '@nestjs/common';
import { RewardService } from './reward.service.js';

// D5: reward engine (pays verified reports, finalizes rewards after the hold).
@Module({
  providers: [RewardService],
  exports: [RewardService],
})
export class WalletModule {}
