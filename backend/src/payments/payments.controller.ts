import { BadRequestException, Controller, HttpCode, Param, Post, UseGuards } from '@nestjs/common';
import { AdminKeyGuard } from './admin-key.guard.js';
import { PaymentsService } from './payments.service.js';

// E3: used by the team member who checks the mobile money statement.
//   curl -X POST -H "x-admin-key: $ADMIN_KEY" http://localhost:3000/payments/<REFERENCE>/approve
//   curl -X POST -H "x-admin-key: $ADMIN_KEY" http://localhost:3000/payments/<REFERENCE>/reject
// 200 = done, 401 = wrong key, 404 = unknown reference, 409 = not pending.
const REFERENCE = /^[A-Z0-9]{6,20}$/;

@Controller('payments')
@UseGuards(AdminKeyGuard)
export class PaymentsController {
  constructor(private readonly payments: PaymentsService) {}

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

// Same format the rules enforce on subscription ids.
function checked(reference: string): string {
  const normalized = reference.trim().toUpperCase();
  if (!REFERENCE.test(normalized)) {
    throw new BadRequestException('reference must be 6 to 20 letters or digits');
  }
  return normalized;
}
