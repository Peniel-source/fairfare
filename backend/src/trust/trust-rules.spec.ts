import { describe, expect, it } from 'vitest';
import { publicAvatar } from './trust-rules.js';

describe('publicAvatar', () => {
  it('keeps a preset id the app offers', () => {
    expect(publicAvatar('w01')).toBe('w01');
    expect(publicAvatar('m08')).toBe('m08');
  });

  it('drops anything else, so the public board never shows it', () => {
    for (const value of [
      'w09',
      'x01',
      'W01',
      ' w01',
      'https://example.com/a.png',
      '',
      3,
      null,
      undefined,
    ]) {
      expect(publicAvatar(value)).toBeNull();
    }
  });
});
