# Architecture

## The one idea: an adapter seam

Every screen talks to a single Dart interface, `PaymentAdapter`
(`app/lib/core/payment_adapter.dart`):

- `payQr(...)` — merchant QR payment
- `sendToVpa(...)` — person-to-person transfer by mobile number / VPA
- `lookupName(vpa)` — beneficiary name inquiry
- `balanceNpr()` / `history()` — account reads

Implementations:

| Adapter | Status | Rails |
|---|---|---|
| `MockNpiAdapter` | ✅ V0 default | In-app mock ledger, instant settlement |
| Wallet sandbox | 🚧 config stub | eSewa / Khalti public test environments |
| NPI adapter | 🔜 V1 | NCHL National Payment Interface + connectIPS via a partner bank/PSP |

Swapping adapters changes where money (test money) moves — never how the
app looks or behaves. That is deliberate: in Nepal, the member-only rails
(NPI, NEPALPAY QR acquiring) are reached through a partner institution,
and the partnership timeline should not block UX development.

## QR parsing

`app/lib/core/emv_qr.dart` parses EMVCo merchant-presented payloads
(TLV format) used by both NEPALPAY QR and FonePay QR: merchant name/city,
merchant account identifier, amount for dynamic QR, currency (524 = NPR).
Scheme is detected from the merchant account information template.

## Backend guarantees

`backend/server.js` is a zero-dependency Node service built around two
invariants:

1. **Double-entry ledger.** Every payment posts a debit and a credit.
   A balance is `SUM(credits) − SUM(debits)` over an account's entries —
   there is no mutable balance to corrupt, and every rupee is traceable.
2. **Idempotency.** `POST /payments/*` requires a client-generated
   `idempotencyKey`. The first request executes and stores its result;
   any retry with the same key returns the stored result. Verified: a
   duplicate request returns the same transaction id and charges once.

V1 moves storage to Postgres (schema sketched at the bottom of
`server.js`), keeping the same API contract.

## Trust & safety by design

- **Name inquiry before send** — receivers are confirmed by name, the
  single most effective defence against wrong-number transfers.
- **Fees in the open** — the confirm sheet shows the fee (रू 0.00 in V0)
  before the user commits, never after.
- **No secrets in the app** — provider credentials live server-side;
  the app holds only short-lived session tokens (V1).
