import { Module } from '@nestjs/common';
import { AdminKeyGuard } from './admin-key.guard.js';
import { PaymentsController } from './payments.controller.js';
import { PaymentsService } from './payments.service.js';

@Module({
  controllers: [PaymentsController],
  providers: [PaymentsService, AdminKeyGuard],
  exports: [PaymentsService],
})
export class PaymentsModule {}
