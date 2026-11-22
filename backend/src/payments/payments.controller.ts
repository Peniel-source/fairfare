import {
  BadRequestException,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AdminKeyGuard } from './admin-key.guard.js';
import { PaymentsService } from './payments.service.js';

// E3: used by the team member who checks the mobile money statement.
// Easiest through the admin script: npm run payments -- list | approve <REF> | reject <REF>
//   curl -H "x-admin-key: $ADMIN_KEY" http://localhost:3000/payments/pending
//   curl -X POST -H "x-admin-key: $ADMIN_KEY" http://localhost:3000/payments/<REFERENCE>/approve
//   curl -X POST -H "x-admin-key: $ADMIN_KEY" http://localhost:3000/payments/<REFERENCE>/reject
// 200 = done, 401 = wrong key, 404 = unknown reference, 409 = not pending.
// MoMo transaction ids are numbers only.
const REFERENCE = /^[0-9]{6,20}$/;

@Controller('payments')
@UseGuards(AdminKeyGuard)
export class PaymentsController {
  constructor(private readonly payments: PaymentsService) {}

  @Get('pending')
  pending() {
    return this.payments.listPending();
  }

  @Post(':reference/approve')
  @HttpCode(200)
  approve(@Param('reference') reference: string) {
    return this.payments.approve(checked(reference));
  }

  @Post(':reference/reject')
  @HttpCode(200)
  reject(@Param('reference') reference: string) {
    return this.payments.reject(checked(reference));
  }
}

// Same format the app accepts (the rules allow a wider [A-Z0-9]{6,20}).
function checked(reference: string): string {
  const normalized = reference.replace(/\s+/g, '');
  if (!REFERENCE.test(normalized)) {
    throw new BadRequestException('reference must be 6 to 20 digits');
  }
  return normalized;
}
