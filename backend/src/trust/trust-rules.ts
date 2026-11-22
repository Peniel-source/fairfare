// E5 trust rules: pure functions so they can be unit tested without Firestore.
export const VERIFIED_DELTA = 5;
export const REJECTED_DELTA = -3;
export const MIN_TRUST = 0;
export const MAX_TRUST = 100;

export function clampTrust(score: number): number {
  return Math.min(MAX_TRUST, Math.max(MIN_TRUST, Math.round(score)));
}

// Missing or malformed scores count as 0 (a brand new passenger).
export function currentTrust(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) ? clampTrust(value) : MIN_TRUST;
}

export function afterVerified(score: unknown): number {
  return clampTrust(currentTrust(score) + VERIFIED_DELTA);
}

export function afterRejected(score: unknown): number {
  return clampTrust(currentTrust(score) + REJECTED_DELTA);
}
