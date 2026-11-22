export const MATCH_TOLERANCE = 0.1;
export const MATCH_WINDOW_MS = 48 * 60 * 60 * 1000;

export type MatchReport = {
  id: string;
  passengerId?: string;
  corridorId: string;
  price: number;
  timeSegment: string;
  status: string;
  createdAt: Date;
  isSeeded?: boolean;
};

// Within 10 percent of the higher price
export function isSimilarPrice(a: number, b: number) {
  return Math.abs(a - b) <= MATCH_TOLERANCE * Math.max(a, b);
}

// Oldest pending report from another passenger that confirms this one
export function findMatch(
  report: MatchReport,
  candidates: MatchReport[],
): MatchReport | null {
  const matches = candidates.filter(
    (other) =>
      other.id !== report.id &&
      other.isSeeded !== true &&
      other.passengerId !== undefined &&
      other.passengerId !== report.passengerId &&
      other.status === 'pending' &&
      other.corridorId === report.corridorId &&
      other.timeSegment === report.timeSegment &&
      isSimilarPrice(other.price, report.price) &&
      Math.abs(other.createdAt.getTime() - report.createdAt.getTime()) <=
        MATCH_WINDOW_MS,
  );
  if (matches.length === 0) return null;
  return matches.reduce((oldest, other) =>
    other.createdAt < oldest.createdAt ? other : oldest,
  );
}

// Pending reports older than 48 hours expire
export function isExpired(createdAt: Date, now: Date) {
  return now.getTime() - createdAt.getTime() > MATCH_WINDOW_MS;
}
