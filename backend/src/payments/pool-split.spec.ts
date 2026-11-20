import { describe, expect, it } from 'vitest';
import { PASS_PRICE_RWF, passEnd, splitPayment } from './pool-split.js';

describe('splitPayment', () => {
  it('splits the Pass price 35/45/20', () => {
    expect(splitPayment(PASS_PRICE_RWF)).toEqual({
      rewardBalance: 700,
      operationsBalance: 900,
      reserveBalance: 400,
    });
  });

  it('gives the rounding remainder to the reserve so parts add up', () => {
    const split = splitPayment(1001);
    expect(split.rewardBalance).toBe(350);
    expect(split.operationsBalance).toBe(450);
    expect(split.rewardBalance + split.operationsBalance + split.reserveBalance).toBe(1001);
  });

  it('refuses negative or fractional amounts', () => {
    expect(() => splitPayment(-1)).toThrow();
    expect(() => splitPayment(10.5)).toThrow();
  });
});

describe('passEnd', () => {
  it('ends 30 days after the start', () => {
    const start = new Date('2026-11-01T10:00:00Z');
    expect(passEnd(start).toISOString()).toBe('2026-12-01T10:00:00.000Z');
  });
});
