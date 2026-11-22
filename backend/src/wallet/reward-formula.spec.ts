import { describe, expect, it } from 'vitest';
import {
  DEFAULT_REWARD_CONFIG,
  holdCutoff,
  readRewardConfig,
  rewardFormula,
} from './reward-formula.js';

describe('rewardFormula', () => {
  it('pays 1.5x the base for the first report on a corridor', () => {
    // One approved Pass puts 700 in the pool: 700 / 20 = 35, x1.5 = 52.5.
    expect(rewardFormula(700, 20, true)).toBe(52);
  });

  it('pays 0.5x the base for a confirming report', () => {
    expect(rewardFormula(700, 20, false)).toBe(17);
  });

  it('matches the concept note example', () => {
    // 350,000 RWF pool, 4,000 expected reports: base 87.5.
    expect(rewardFormula(350_000, 4000, true)).toBe(131);
    expect(rewardFormula(350_000, 4000, false)).toBe(43);
  });

  it('always rounds down to whole points', () => {
    expect(rewardFormula(101, 2, false)).toBe(25);
    expect(rewardFormula(100.9, 3, true)).toBe(50);
  });

  it('treats zero or missing expected reports as 1 instead of dividing by zero', () => {
    expect(rewardFormula(100, 0, false)).toBe(50);
    expect(rewardFormula(100, -5, false)).toBe(50);
    expect(rewardFormula(100, Number.NaN, false)).toBe(50);
  });

  it('never pays more than the pool holds', () => {
    expect(rewardFormula(100, 0, true)).toBe(100);
    expect(rewardFormula(10, 1, true)).toBe(10);
  });

  it('pays nothing from an empty, negative or broken pool', () => {
    expect(rewardFormula(0, 20, true)).toBe(0);
    expect(rewardFormula(-50, 20, true)).toBe(0);
    expect(rewardFormula(Number.NaN, 20, true)).toBe(0);
    expect(rewardFormula(Number.POSITIVE_INFINITY, 20, true)).toBe(0);
  });

  it('shrinks as the pool shrinks', () => {
    const rewards = [700, 350, 70, 10].map((pool) =>
      rewardFormula(pool, 20, true),
    );
    expect(rewards).toEqual([52, 26, 5, 0]);
  });
});

describe('holdCutoff', () => {
  it('goes back by the hold', () => {
    const now = new Date('2026-11-22T12:00:00Z');
    expect(holdCutoff(now, 1440).toISOString()).toBe(
      '2026-11-21T12:00:00.000Z',
    );
    expect(holdCutoff(now, 0).toISOString()).toBe('2026-11-22T12:00:00.000Z');
  });
});

describe('readRewardConfig', () => {
  const from = (env: Record<string, string>) =>
    readRewardConfig((key) => env[key]);

  it('uses the defaults when nothing is set', () => {
    expect(from({})).toEqual(DEFAULT_REWARD_CONFIG);
    expect(DEFAULT_REWARD_CONFIG).toEqual({
      expectedReports: 20,
      holdMinutes: 1440,
      sweepIntervalMs: 60_000,
    });
  });

  it('reads valid values', () => {
    expect(
      from({
        REWARD_EXPECTED_REPORTS: '50',
        REWARD_HOLD_MINUTES: '2',
        REWARD_SWEEP_INTERVAL_MS: '5000',
      }),
    ).toEqual({ expectedReports: 50, holdMinutes: 2, sweepIntervalMs: 5000 });
  });

  it('allows a zero hold for testing', () => {
    expect(from({ REWARD_HOLD_MINUTES: '0' }).holdMinutes).toBe(0);
  });

  it('keeps the default for invalid values', () => {
    expect(
      from({
        REWARD_EXPECTED_REPORTS: '0',
        REWARD_HOLD_MINUTES: 'soon',
        REWARD_SWEEP_INTERVAL_MS: '10',
      }),
    ).toEqual(DEFAULT_REWARD_CONFIG);
    expect(from({ REWARD_HOLD_MINUTES: '-1' }).holdMinutes).toBe(1440);
    expect(from({ REWARD_EXPECTED_REPORTS: '  ' }).expectedReports).toBe(20);
  });
});
