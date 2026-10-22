# Nepal Payment App — Path A Prototype Plan

Decision: Path A chosen by user 2026-10-22 — prototype on partner/sandbox rails first,
own PSP licence later (Path B parked).

## What "partner sandbox" actually means in Nepal (verified 2026-10-22)

Two different worlds — don't mix them:

### A. Self-serve sandboxes (no licence, no partner, start TODAY)
- **eSewa ePay test environment** — public test merchant (EPAYTEST) + test user
  accounts published in eSewa's own developer docs. Full initiate → pay → verify
  flow in test money.
- **Khalti sandbox** — test keys + test mobile numbers/PIN/OTP in Khalti dev docs.
  Same initiate → verify flow.
- **Aggregators** (PayBridgeNP, APINepal) — one API over eSewa/Khalti/FonePay,
  free plan with full sandbox, separate sandbox/live keys. Useful if you don't
  want three integrations, but adds a middleman you'd drop later.
- These cover **merchant checkout-style payments** (your app asks a wallet to pay).
  They do NOT give you GPay-style account-to-account P2P.

### B. Member-only rails (need a partner BFI/PSP — post-Dashain step)
- **NCHL NPI** is "an open API for the members" — BFIs and PSPs, not individuals.
  NEPALPAY QR issuer/acquirer APIs are likewise "available for the member BFIs
  or PSPs". connectIPS P2P, NEPALPAY Instant (VPA transfers), and Request-to-Pay
  all sit behind membership.
- **FonePay merchant accounts** are issued via your bank ("you usually cannot
  get a Fonepay merchant account directly from Fonepay — visit your bank and
  request Fonepay Merchant QR Integration + API access for Dynamic QR").
- Bank acquiring/onboarding procedure typically takes 2–4 weeks with company
  + tax documents and an MDR/settlement agreement.
- **Path A partner move (after offices reopen ~Mon Oct 26):** pick ONE bank
  where you'll hold the settlement account, and approach it for (1) FonePay
  merchant QR API access and (2) an intro to NCHL technical membership via
  that bank. No outreach before user approval.

## V0 prototype scope — what you build NOW without any partner

Build the real app + real backend, with the member-only rails behind a
mock adapter that has the same interface as the real NPI adapter. When the
partner lands, you swap the adapter, not the app.

### The 5 flows (build in this order)
1. **QR pay** — scan NEPALPAY QR + FonePay QR (both are EMVCo payloads —
   parse merchant id, amount, currency 524 NPR), beautiful confirm sheet
   (merchant name, amount, fee = 0 shown plainly), MPIN/biometric confirm,
   result in <2s against mock ledger; eSewa/Khalti sandbox wired as the
   first real-money-path test.
2. **Send money (VPA/mobile)** — NEPALPAY Instant style: pay to a mobile
   number / VPA handle, name-lookup confirm before send. Mock adapter in V0.
3. **Request money + split bill** — Request-to-Pay style pull, split with
   contacts, pending-request inbox. All internal to your ledger in V0.
4. **Bank link** — connectIPS-style linked-account flow (redirect + callback),
   mocked in V0; balance fetch + history UI real against your own backend.
5. **Bills + history** — 2–3 mock billers (electricity, internet, top-up),
   unified history with search, receipts, dispute button (UI + flow, no
   backend case system yet).

### Backend (from day one — this is what makes it feel like GPay later)
- API gateway → payment orchestration (routes: QR rails / wallet sandbox /
  mock-NPI; timeouts, one auto-retry, circuit-breaker on failure)
- **Ledger: double-entry, idempotency key on EVERY payment request** —
  a retry can never double-charge. This is the #1 trust feature.
- Risk basics: velocity limits per account/device, step-up auth (biometric)
  above a threshold amount
- Notifications (in-app + push), reconciliation report vs sandbox results,
  full audit log

### Security (V0, non-negotiable)
- Device binding + biometrics + MPIN; MPIN never stored raw (salted hash /
  secure enclave on device)
- Tokens, not credentials, between app and backend; short-lived sessions
- No real money, no real bank credentials in V0 — sandbox + mock only

### Success bar for V0 (prove before chasing a partner)
- QR pay completes p95 < 2s (app-side), success rate ≥ 99% on sandbox/mock
- Zero double-charges across forced-retry / kill-app-mid-payment tests
- A stranger can complete Flow 1 without instructions (same test-kit
  approach as Aura Scanner)

## Stack decision (user's call — recommendation: Flutter)
- **Flutter (recommended):** one codebase, Android first, iOS later for free;
  fastest path for a solo builder; QR/camera/biometric plugins are mature.
- **Native Kotlin:** reuses your Aura Scanner skills/tooling, best Android
  performance, but iOS means a second app later.
- Backend: your call too — a single small service (Node or Kotlin/Ktor) +
  Postgres for the ledger is enough for V0.

## Timeline sketch
- Dashain week (now → Oct 25): app shell, QR parse + confirm sheet, mock
  ledger, Flow 1 end-to-end on eSewa/Khalti sandbox. All self-serve.
- From Oct 26: partner-bank approach (user-approved), Flows 2–5, hardening.
- V1 (live) still needs: PSP licence (Path B) OR going live under the
  partner's licence as their tech/front-end — decide with the partner.

## Still open / not verified
- NRB capital threshold conflict (Rs 10M earlier vs Rs 50M in Permit Policy
  2023 reporting) — only matters for Path B, verify with NRB before budgeting.
- Which bank — user's choice; needs an account relationship + Dashain is
  over before outreach makes sense.
- Nothing has been built, signed up for, or contacted yet.
