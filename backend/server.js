// NepPay V0 backend — zero-dependency Node server.
//
// The two ideas that matter, enforced server-side:
//  1) DOUBLE-ENTRY LEDGER: every payment writes a debit + a credit entry.
//     Balances are SUMS of entries, never a mutable number that can drift.
//  2) IDEMPOTENCY: every payment request carries a client-generated key.
//     A retry with the same key returns the ORIGINAL result — it can never
//     charge twice, even if the app was killed mid-payment.
//
// Storage is in-memory for V0. Swap `store` for Postgres before any real
// money moves (schema notes at the bottom of this file).

import { createServer } from 'node:http';
import { randomUUID } from 'node:crypto';

const store = {
  entries: [], // {id, txnId, account, debit, credit, at, memo}
  byIdempotencyKey: new Map(), // key -> result object
  accounts: new Map([ // seed demo accounts
    ['user:me', { name: 'You (demo)' }],
    ['merchant:demo', { name: 'DEMO MART' }],
    ['vpa:9800000001', { name: 'R*** K***' }],
  ]),
};

function balance(account) {
  return store.entries
    .filter((e) => e.account === account)
    .reduce((s, e) => s + e.credit - e.debit, 0);
}

// Seed: opening balance for the demo user (credit from a "float" account).
function post(txnId, legs, memo) {
  const at = new Date().toISOString();
  for (const leg of legs) {
    store.entries.push({ id: randomUUID(), txnId, at, memo, ...leg });
  }
}
post('seed', [
  { account: 'system:float', debit: 25430, credit: 0 },
  { account: 'user:me', debit: 0, credit: 25430 },
], 'Opening balance (mock)');

function doPayment({ from, to, toName, amount, idempotencyKey, memo }) {
  if (store.byIdempotencyKey.has(idempotencyKey)) {
    return store.byIdempotencyKey.get(idempotencyKey); // replay, never re-charge
  }
  if (!(amount > 0)) return { ok: false, message: 'Amount must be positive' };
  if (balance(from) < amount) return { ok: false, message: 'Insufficient balance' };
  const txnId = 'TXN' + Date.now().toString(36).toUpperCase();
  post(txnId, [
    { account: from, debit: amount, credit: 0 },
    { account: to, debit: 0, credit: amount },
  ], memo || `Payment to ${toName || to}`);
  const result = { ok: true, txnId, balance: balance(from) };
  store.byIdempotencyKey.set(idempotencyKey, result);
  return result;
}

function json(res, code, obj) {
  res.writeHead(code, { 'content-type': 'application/json' });
  res.end(JSON.stringify(obj));
}

const server = createServer(async (req, res) => {
  const url = new URL(req.url, 'http://localhost');
  const body = await new Promise((resolve) => {
    let d = '';
    req.on('data', (c) => (d += c));
    req.on('end', () => resolve(d ? JSON.parse(d) : {}));
  }).catch(() => ({}));

  if (req.method === 'GET' && url.pathname === '/balance') {
    return json(res, 200, { account: 'user:me', balance: balance('user:me') });
  }
  if (req.method === 'GET' && url.pathname === '/history') {
    const mine = store.entries.filter((e) => e.account === 'user:me');
    return json(res, 200, { entries: mine });
  }
  if (req.method === 'GET' && url.pathname.startsWith('/lookup/')) {
    const vpa = decodeURIComponent(url.pathname.slice('/lookup/'.length));
    const acct = store.accounts.get('vpa:' + vpa);
    return json(res, acct ? 200 : 404, acct ? { name: acct.name } : { ok: false });
  }
  if (req.method === 'POST' && url.pathname === '/payments/qr') {
    const { merchantId, merchantName, amount, idempotencyKey } = body;
    if (!idempotencyKey) return json(res, 400, { ok: false, message: 'idempotencyKey required' });
    return json(res, 200, doPayment({
      from: 'user:me', to: 'merchant:' + (merchantId || 'unknown'),
      toName: merchantName, amount, idempotencyKey, memo: `QR pay ${merchantName || ''}`,
    }));
  }
  if (req.method === 'POST' && url.pathname === '/payments/send') {
    const { vpa, amount, idempotencyKey } = body;
    if (!idempotencyKey) return json(res, 400, { ok: false, message: 'idempotencyKey required' });
    return json(res, 200, doPayment({
      from: 'user:me', to: 'vpa:' + vpa, amount, idempotencyKey, memo: `Send to ${vpa}`,
    }));
  }
  return json(res, 404, { ok: false, message: 'not found' });
});

const port = process.env.PORT || 8787;
server.listen(port, () => console.log(`NepPay backend on http://localhost:${port} (mock rails, no real money)`));

// Postgres schema for V1 (when a partner + licence path is real):
//   accounts(id text pk, name text)
//   ledger_entries(id uuid pk, txn_id text, account text fk, debit numeric,
//                  credit numeric, memo text, created_at timestamptz)
//   payments(idempotency_key text pk, txn_id text, result jsonb, created_at)
// Wrap doPayment in a single DB transaction with the idempotency insert
// FIRST (unique violation = replay) so the guarantee survives restarts.
