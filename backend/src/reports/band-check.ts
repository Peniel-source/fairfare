export const BAND_MIN_RATIO = 0.5;
export const BAND_MAX_RATIO = 1.5;
// Heavy rain or late night
export const BAND_WIDE_MAX_RATIO = 2.0;
// A corridor needs this many reports before the band check runs
export const NEW_CORRIDOR_THRESHOLD = 3;

export type CorridorBand = { median: number; sampleSize: number };

export type BandResult =
  { ok: true; skipped: boolean } | { ok: false; reason: string };

// Accepted range around a median
export function bandRange(
  median: number,
  timeSegment: string,
  weather: string,
) {
  const wide = weather === 'heavyRain' || timeSegment === 'lateNight';
  return {
    low: Math.round(median * BAND_MIN_RATIO),
    high: Math.round(median * (wide ? BAND_WIDE_MAX_RATIO : BAND_MAX_RATIO)),
  };
}

// Checks a price against the corridor's usual range
export function bandCheck(
  price: number,
  corridor: CorridorBand | null,
  timeSegment: string,
  weather: string,
): BandResult {
  if (!corridor || corridor.sampleSize < NEW_CORRIDOR_THRESHOLD) {
    return { ok: true, skipped: true };
  }
  const { low, high } = bandRange(corridor.median, timeSegment, weather);
  if (price >= low && price <= high) return { ok: true, skipped: false };
  return {
    ok: false,
    reason: `Price is outside the usual range for this route (${low} to ${high} RWF)`,
  };
}
