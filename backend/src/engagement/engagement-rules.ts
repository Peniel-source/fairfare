// daily streak and badges. Pure, so unit testable.
// Badge ids must match app/lib/features/profile/domain/badges.dart.
export const BADGE_CORRIDOR_PIONEER = 'corridor_pioneer';
export const BADGE_WEEK_STREAK = 'week_streak';
export const BADGE_TEN_VERIFIED = 'ten_verified';

export const WEEK_STREAK_DAYS = 7;
export const TEN_VERIFIED_COUNT = 10;

// Kigali is UTC+2 all year (no daylight saving), so days roll over at
// 22:00 UTC, not at midnight UTC.
const KIGALI_OFFSET_MS = 2 * 60 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;

export function kigaliDay(date: Date): number {
  return Math.floor((date.getTime() + KIGALI_OFFSET_MS) / DAY_MS);
}

// Same Kigali day keeps the streak, the next day adds one, a gap restarts at 1.
export function nextStreak(previous: number, lastReportDate: Date | null, now: Date): number {
  const streak = Number.isFinite(previous) && previous > 0 ? Math.floor(previous) : 0;
  if (!lastReportDate || streak === 0) return 1;
  const gap = kigaliDay(now) - kigaliDay(lastReportDate);
  if (gap <= 0) return streak;
  if (gap === 1) return streak + 1;
  return 1;
}

export type BadgeInput = {
  streak: number;
  verifiedCount: number;
  isFirstOnCorridor: boolean;
};

// Badges are never taken away, so only new ones are returned.
export function newBadges(earned: readonly string[], input: BadgeInput): string[] {
  const result: string[] = [];
  const add = (id: string, when: boolean) => {
    if (when && !earned.includes(id)) result.push(id);
  };
  add(BADGE_CORRIDOR_PIONEER, input.isFirstOnCorridor);
  add(BADGE_WEEK_STREAK, input.streak >= WEEK_STREAK_DAYS);
  add(BADGE_TEN_VERIFIED, input.verifiedCount >= TEN_VERIFIED_COUNT);
  return result;
}
