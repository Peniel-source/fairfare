import { describe, expect, it } from 'vitest';
import {
  findMatch,
  isExpired,
  isSimilarPrice,
  type MatchReport,
} from './corroboration.js';

const hour = 60 * 60 * 1000;
const start = new Date('2026-11-20T08:00:00Z');

function report(overrides: Partial<MatchReport> = {}): MatchReport {
  return {
    id: 'mine',
    passengerId: 'p1',
    corridorId: 'alu-downtown',
    price: 1000,
    timeSegment: 'morning',
    status: 'pending',
    createdAt: start,
    ...overrides,
  };
}

const other = (overrides: Partial<MatchReport> = {}) =>
  report({ id: 'other', passengerId: 'p2', ...overrides });

describe('isSimilarPrice', () => {
  it('is true within 10 percent', () => {
    expect(isSimilarPrice(1000, 1100)).toBe(true);
    expect(isSimilarPrice(1000, 900)).toBe(true);
  });

  it('is false beyond 10 percent', () => {
    expect(isSimilarPrice(1000, 1150)).toBe(false);
  });
});

describe('findMatch', () => {
  it('matches a similar price from another passenger', () => {
    expect(findMatch(report(), [other({ price: 1050 })])?.id).toBe('other');
  });

  it('never matches the same passenger', () => {
    expect(findMatch(report(), [other({ passengerId: 'p1' })])).toBeNull();
  });

  it('never matches the report itself', () => {
    expect(findMatch(report(), [report()])).toBeNull();
  });

  it('does not match a price outside 10 percent', () => {
    expect(findMatch(report(), [other({ price: 1200 })])).toBeNull();
  });

  it('does not match a different time of day', () => {
    expect(findMatch(report(), [other({ timeSegment: 'evening' })])).toBeNull();
  });

  it('does not match a different corridor', () => {
    expect(
      findMatch(report(), [other({ corridorId: 'downtown-alu' })]),
    ).toBeNull();
  });

  it('does not match after 48 hours', () => {
    const late = new Date(start.getTime() + 49 * hour);
    expect(findMatch(report(), [other({ createdAt: late })])).toBeNull();
  });

  it('matches just inside 48 hours', () => {
    const inside = new Date(start.getTime() + 47 * hour);
    expect(findMatch(report(), [other({ createdAt: inside })])?.id).toBe(
      'other',
    );
  });

  it('never matches a seed report', () => {
    expect(
      findMatch(report(), [other({ isSeeded: true, passengerId: undefined })]),
    ).toBeNull();
    expect(findMatch(report(), [other({ isSeeded: true })])).toBeNull();
  });

  it('only matches pending reports', () => {
    expect(findMatch(report(), [other({ status: 'verified' })])).toBeNull();
    expect(findMatch(report(), [other({ status: 'rejected' })])).toBeNull();
  });

  it('picks the oldest when several match', () => {
    const match = findMatch(report(), [
      other({ id: 'newer', createdAt: new Date(start.getTime() - 1 * hour) }),
      other({ id: 'older', createdAt: new Date(start.getTime() - 5 * hour) }),
    ]);
    expect(match?.id).toBe('older');
  });
});

describe('isExpired', () => {
  it('is false within 48 hours and true after', () => {
    expect(isExpired(start, new Date(start.getTime() + 47 * hour))).toBe(false);
    expect(isExpired(start, new Date(start.getTime() + 49 * hour))).toBe(true);
  });
});
