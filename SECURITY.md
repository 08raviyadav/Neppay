# Security Policy

## Project status

NepPay is a **prototype**. It runs only against public payment sandboxes
and mock adapters, and it must never be used to move real money. Security
reports are still taken seriously: today's prototype code is the base of
tomorrow's production system.

## Reporting a vulnerability

Please **do not** open a public issue for security problems.

Instead, use GitHub's private vulnerability reporting:
**Security → Report a vulnerability** on this repository. Include:

- What the issue is and where it lives (file/endpoint)
- Steps to reproduce, or a proof of concept
- What an attacker could achieve with it

You can expect an acknowledgement within 7 days. Please give us a
reasonable window to fix the issue before disclosing it publicly.

## Especially sensitive areas

Reports in these areas are high priority:

- Anything that could cause a **double charge** (idempotency bypass)
- Ledger integrity (entries that don't balance, negative-balance paths)
- Authentication / MPIN / biometric handling in the app
- Secrets accidentally committed to the repository
