import { describe, expect, it } from 'vitest';
import { bandCheck, bandRange } from './band-check.js';

const corridor = { median: 1000, sampleSize: 20 };

describe('bandRange', () => {
  it('is 50 to 150 percent of the median normally', () => {
    expect(bandRange(1000, 'midday', 'clear')).toEqual({
      low: 500,
      high: 1500,
    });
  });

  it('goes up to 200 percent in heavy rain', () => {
    expect(bandRange(1000, 'midday', 'heavyRain').high).toBe(2000);
  });

  it('goes up to 200 percent late at night', () => {
    expect(bandRange(1000, 'lateNight', 'clear').high).toBe(2000);
  });
});

describe('bandCheck', () => {
  it('accepts a price inside the range', () => {
    expect(bandCheck(1200, corridor, 'morning', 'clear')).toEqual({
      ok: true,
      skipped: false,
    });
  });

  it('accepts the edges of the range', () => {
    expect(bandCheck(500, corridor, 'morning', 'clear').ok).toBe(true);
    expect(bandCheck(1500, corridor, 'morning', 'clear').ok).toBe(true);
  });

  it('rejects a price above the range with a reason', () => {
    const result = bandCheck(1600, corridor, 'morning', 'clear');
    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.reason).toContain('500 to 1500 RWF');
  });

  it('rejects a price below the range', () => {
    expect(bandCheck(400, corridor, 'morning', 'clear').ok).toBe(false);
  });

  it('accepts a rain price that would fail in clear weather', () => {
    expect(bandCheck(1800, corridor, 'morning', 'clear').ok).toBe(false);
    expect(bandCheck(1800, corridor, 'morning', 'heavyRain').ok).toBe(true);
  });

  it('skips the check on a corridor with fewer than 3 reports', () => {
    expect(
      bandCheck(99999, { median: 1000, sampleSize: 2 }, 'morning', 'clear'),
    ).toEqual({
      ok: true,
      skipped: true,
    });
  });

  it('skips the check when the corridor has no stats', () => {
    expect(bandCheck(99999, null, 'morning', 'clear')).toEqual({
      ok: true,
      skipped: true,
    });
  });
});
