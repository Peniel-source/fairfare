import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { timingSafeEqual } from 'node:crypto';

// Lets a request through only when its x-admin-key header equals ADMIN_KEY.
// With no ADMIN_KEY configured, or one shorter than MIN_ADMIN_KEY_LENGTH,
// every request is refused, so a weak key can never approve payments.
// Generate one with: openssl rand -hex 32
export const MIN_ADMIN_KEY_LENGTH = 32;

@Injectable()
export class AdminKeyGuard implements CanActivate {
  constructor(private readonly config: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const expected = this.config.get<string>('ADMIN_KEY') ?? '';
    const request = context.switchToHttp().getRequest<{ headers: Record<string, unknown> }>();
    const given = request.headers['x-admin-key'];

    if (
      expected.length < MIN_ADMIN_KEY_LENGTH ||
      typeof given !== 'string' ||
      !sameKey(given, expected)
    ) {
      throw new UnauthorizedException('invalid admin key');
    }
    return true;
  }
}

function sameKey(a: string, b: string): boolean {
  const left = Buffer.from(a);
  const right = Buffer.from(b);
  return left.length === right.length && timingSafeEqual(left, right);
}
