// D5 reward rules: pure functions so they can be unit tested without Firestore.
//
// A verified report earns a share of the reward pool (poolLedger/main
// rewardBalance, filled by E3 with 35% of every approved Pass). The share
// shrinks as the pool shrinks, so the pool can never be paid below zero.

/** A first report on a corridor adds new information, so it earns more. */
export const FIRST_REPORT_MULTIPLIER = 1.5;

/** A report that only confirms an existing price earns less. */
export const CONFIRMING_REPORT_MULTIPLIER = 0.5;

/**
 * Points for one verified report.
 *
 * The base is the pool divided by the number of verified reports the pool is
 * expected to cover (at least 1, so it never divides by zero). That base is
 * multiplied by 1.5 for the first report on a corridor or 0.5 for a
 * confirming one, rounded down, and never more than the pool holds.
 *
 * Example: a pool of 700 and 20 expected reports gives a base of 35, so 52
 * points for a first report and 17 for a confirming one.
 */
export function rewardFormula(
  poolBalance: number,
  expectedReports: number,
  isFirstOnCorridor: boolean,
): number {
  if (!Number.isFinite(poolBalance) || poolBalance <= 0) return 0;
  const pool = Math.floor(poolBalance);
  const expected = Number.isFinite(expectedReports)
    ? Math.max(1, Math.floor(expectedReports))
    : 1;
  const multiplier = isFirstOnCorridor
    ? FIRST_REPORT_MULTIPLIER
    : CONFIRMING_REPORT_MULTIPLIER;
  const reward = Math.floor((pool / expected) * multiplier);
  return Math.min(pool, Math.max(0, reward));
}

/** Entries created at or before this moment have finished their hold. */
export function holdCutoff(now: Date, holdMinutes: number): Date {
  return new Date(now.getTime() - holdMinutes * 60 * 1000);
}

export type RewardConfig = {
  /** How many verified reports the current pool should cover. */
  expectedReports: number;
  /** How long a reward stays pending before it can be cashed out. */
  holdMinutes: number;
  /** How often the server looks for rewards that finished their hold. */
  sweepIntervalMs: number;
};

export const DEFAULT_REWARD_CONFIG: RewardConfig = {
  expectedReports: 20,
  holdMinutes: 24 * 60,
  sweepIntervalMs: 60 * 1000,
};

/**
 * Reads the optional REWARD_* settings from .env. A missing or invalid value
 * keeps the default, so a typo can never stop rewards or pay a huge amount.
 * For the demo, set REWARD_HOLD_MINUTES to a few minutes.
 */
export function readRewardConfig(
  get: (key: string) => string | undefined,
): RewardConfig {
  return {
    expectedReports: numberOr(
      get('REWARD_EXPECTED_REPORTS'),
      DEFAULT_REWARD_CONFIG.expectedReports,
      1,
    ),
    holdMinutes: numberOr(
      get('REWARD_HOLD_MINUTES'),
      DEFAULT_REWARD_CONFIG.holdMinutes,
      0,
    ),
    sweepIntervalMs: numberOr(
      get('REWARD_SWEEP_INTERVAL_MS'),
      DEFAULT_REWARD_CONFIG.sweepIntervalMs,
      1000,
    ),
  };
}

function numberOr(
  raw: string | undefined,
  fallback: number,
  min: number,
): number {
  if (raw === undefined || raw.trim() === '') return fallback;
  const value = Number(raw);
  return Number.isFinite(value) && value >= min ? value : fallback;
}
