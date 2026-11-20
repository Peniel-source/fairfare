import { describe, expect, it } from 'vitest';
import { formatPending, interpret, parseArgs } from './payments-cli.js';

describe('payments admin script', () => {
  it('parses list, approve and reject', () => {
    expect(parseArgs(['list'])).toEqual({ command: 'list' });
    expect(parseArgs(['approve', ' abc123 '])).toEqual({ command: 'approve', reference: 'ABC123' });
    expect(parseArgs(['reject', 'XYZ789'])).toEqual({ command: 'reject', reference: 'XYZ789' });
  });

  it('refuses anything else with the usage line', () => {
    for (const argv of [[], ['approve'], ['delete', 'ABC123'], ['list', 'extra']]) {
      expect(parseArgs(argv)).toHaveProperty('error');
    }
  });

  it('formats pending payments with who paid', () => {
    expect(formatPending([])).toBe('No pending payments.');
    const out = formatPending([
      {
        reference: 'ABC123',
        amount: 2000,
        passengerId: 'p1',
        email: 'a@x.rw',
        displayName: 'Aline',
      },
    ]);
    expect(out).toContain('1 pending:');
    expect(out).toContain('ABC123');
    expect(out).toContain('Aline <a@x.rw>');
  });
});

describe('payments admin script: server answers', () => {
  const base = 'http://localhost:3000';
  const approve = { command: 'approve' as const, reference: 'ABC123' };

  it('shows the list and a real approval', () => {
    expect(interpret({ command: 'list' }, 200, 'OK', [], base)).toEqual({
      ok: true,
      text: 'No pending payments.',
    });
    const done = interpret(
      approve,
      200,
      'OK',
      { reference: 'ABC123', status: 'active', endsAt: 'X' },
      base,
    );
    expect(done).toEqual({ ok: true, text: 'approved ABC123: Pass active until X' });
  });

  it('refuses a web page or any other app on the port', () => {
    for (const body of [undefined, {}, 'html']) {
      expect(interpret({ command: 'list' }, 200, 'OK', body, base).ok).toBe(false);
      expect(interpret(approve, 200, 'OK', body, base).ok).toBe(false);
      expect(interpret(approve, 405, 'Not Allowed', body, base).text).toContain('not the FairFare');
    }
  });

  it('refuses an approval reply for a different reference', () => {
    const other = { reference: 'OTHER1', status: 'active' };
    expect(interpret(approve, 200, 'OK', other, base).ok).toBe(false);
  });

  it('shows the backend error message', () => {
    const conflict = { message: 'subscription ABC123 is active, not pending' };
    expect(interpret(approve, 409, 'Conflict', conflict, base)).toEqual({
      ok: false,
      text: '409: subscription ABC123 is active, not pending',
    });
  });
});
