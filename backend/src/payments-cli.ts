// E3 admin script for Pass payments. Talks to the running server's protected
// /payments endpoints, so every action still goes through the ADMIN_KEY check.
//
//   npm run payments -- list                 pending payments to check
//   npm run payments -- approve <REFERENCE>  after finding it on the MoMo statement
//   npm run payments -- reject <REFERENCE>   when it is not on the statement
//
// Reads ADMIN_KEY (and optionally PAYMENTS_API_URL, default
// http://localhost:3000) from the environment or backend/.env.

type Pending = {
  reference: string;
  amount: number;
  passengerId: string;
  email: string | null;
  displayName: string | null;
};

const USAGE = 'usage: npm run payments -- list | approve <REFERENCE> | reject <REFERENCE>';

export function parseArgs(
  argv: string[],
): { command: 'list' } | { command: 'approve' | 'reject'; reference: string } | { error: string } {
  const [command, reference] = argv;
  if (command === 'list' && argv.length === 1) return { command };
  if ((command === 'approve' || command === 'reject') && argv.length === 2 && reference) {
    return { command, reference: reference.trim().toUpperCase() };
  }
  return { error: USAGE };
}

export function formatPending(rows: Pending[]): string {
  if (rows.length === 0) return 'No pending payments.';
  const lines = rows.map(
    (r) =>
      `${r.reference.padEnd(20)} ${String(r.amount).padStart(6)} RWF  ` +
      `${r.displayName ?? '(no name)'} <${r.email ?? 'unknown email'}>  ${r.passengerId}`,
  );
  return [`${rows.length} pending:`, ...lines].join('\n');
}

async function main(): Promise<number> {
  const args = parseArgs(process.argv.slice(2));
  if ('error' in args) {
    console.error(args.error);
    return 2;
  }
  const key = process.env.ADMIN_KEY;
  if (!key) {
    console.error('ADMIN_KEY is not set (put it in backend/.env)');
    return 2;
  }
  const base = (process.env.PAYMENTS_API_URL ?? 'http://localhost:3000').replace(/\/$/, '');
  const headers = { 'x-admin-key': key };

  const url =
    args.command === 'list'
      ? `${base}/payments/pending`
      : `${base}/payments/${encodeURIComponent(args.reference)}/${args.command}`;

  let response: Response;
  try {
    response = await fetch(url, { method: args.command === 'list' ? 'GET' : 'POST', headers });
  } catch {
    console.error(`could not reach the server at ${base}; is it running (npm run start:dev)?`);
    return 1;
  }

  const isJson = (response.headers.get('content-type') ?? '').includes('application/json');
  const body: unknown = isJson ? await response.json().catch(() => undefined) : undefined;
  const result = interpret(args, response.status, response.statusText, body, base);
  if (result.ok) console.log(result.text);
  else console.error(result.text);
  return result.ok ? 0 : 1;
}

const NOT_FAIRFARE = (base: string) =>
  `the server at ${base} is not the FairFare backend (another app may be using that port). ` +
  'Start the backend (npm run start:dev) or set PAYMENTS_API_URL to where it runs.';

// Turns the server's answer into what the admin sees. Anything that is not
// the exact reply the FairFare backend sends is refused, so a different app
// on the same port can never look like a successful approval.
export function interpret(
  args: { command: 'list' } | { command: 'approve' | 'reject'; reference: string },
  status: number,
  statusText: string,
  body: unknown,
  base: string,
): { ok: boolean; text: string } {
  const obj = typeof body === 'object' && body !== null ? (body as Record<string, unknown>) : {};

  if (status < 200 || status >= 300) {
    // Nest sends message as a string, or a list of strings for validation errors.
    const message = Array.isArray(obj.message) ? obj.message.join(', ') : obj.message;
    if (typeof message !== 'string') return { ok: false, text: NOT_FAIRFARE(base) };
    return { ok: false, text: `${status}: ${message || statusText}` };
  }

  if (args.command === 'list') {
    if (!Array.isArray(body)) return { ok: false, text: NOT_FAIRFARE(base) };
    return { ok: true, text: formatPending(body as Pending[]) };
  }

  const expected = args.command === 'approve' ? 'active' : 'rejected';
  if (obj.reference !== args.reference || obj.status !== expected) {
    return { ok: false, text: NOT_FAIRFARE(base) };
  }
  return args.command === 'approve'
    ? { ok: true, text: `approved ${args.reference}: Pass active until ${String(obj.endsAt)}` }
    : { ok: true, text: `rejected ${args.reference}` };
}

// Only run when executed directly, not when imported by the tests.
if (import.meta.url === `file://${process.argv[1]}`) {
  process.exitCode = await main();
}
