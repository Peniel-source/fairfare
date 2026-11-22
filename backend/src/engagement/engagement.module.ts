import { Module } from '@nestjs/common';
import { EngagementService } from './engagement.service.js';

@Module({
  providers: [EngagementService],
  exports: [EngagementService],
})
export class EngagementModule {}
