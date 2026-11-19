import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { timingSafeEqual } from 'node:crypto';

// Lets a request through only when its x-admin-key header equals ADMIN_KEY.
// With no ADMIN_KEY configured, every request is refused.
@Injectable()
export class AdminKeyGuard implements CanActivate {
  constructor(private readonly config: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const expected = this.config.get<string>('ADMIN_KEY') ?? '';
    const request = context.switchToHttp().getRequest<{ headers: Record<string, unknown> }>();
    const given = request.headers['x-admin-key'];

    if (!expected || typeof given !== 'string' || !sameKey(given, expected)) {
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
