import { UnauthorizedException, type ExecutionContext } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { describe, expect, it } from 'vitest';
import { AdminKeyGuard } from './admin-key.guard.js';

const STRONG_KEY = 'a'.repeat(64);

function guardWith(adminKey: string | undefined) {
  return new AdminKeyGuard({ get: () => adminKey } as unknown as ConfigService);
}

function requestWith(headers: Record<string, unknown>): ExecutionContext {
  return {
    switchToHttp: () => ({ getRequest: () => ({ headers }) }),
  } as unknown as ExecutionContext;
}

describe('AdminKeyGuard', () => {
  it('lets the right key through', () => {
    expect(guardWith(STRONG_KEY).canActivate(requestWith({ 'x-admin-key': STRONG_KEY }))).toBe(
      true,
    );
  });

  it('refuses a wrong or missing key', () => {
    const guard = guardWith(STRONG_KEY);
    expect(() => guard.canActivate(requestWith({ 'x-admin-key': 'b'.repeat(64) }))).toThrow(
      UnauthorizedException,
    );
    expect(() => guard.canActivate(requestWith({}))).toThrow(UnauthorizedException);
  });

  it('refuses everything when ADMIN_KEY is unset or too short', () => {
    expect(() => guardWith(undefined).canActivate(requestWith({ 'x-admin-key': '' }))).toThrow(
      UnauthorizedException,
    );
    expect(() => guardWith('short').canActivate(requestWith({ 'x-admin-key': 'short' }))).toThrow(
      UnauthorizedException,
    );
  });
});
