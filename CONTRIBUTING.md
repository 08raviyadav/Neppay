# Contributing to NepPay

Thanks for your interest in making payments in Nepal feel effortless.
This is a young project — small, focused contributions land fastest.

## Getting set up

1. Fork the repo and clone your fork.
2. Backend: `cd backend && node server.js` (Node 18+, zero dependencies).
3. App: install the [Flutter SDK](https://docs.flutter.dev/get-started/install),
   then `cd app && flutter pub get && flutter run`.

## Ground rules

- **No real money, ever, in this repo.** Development happens against
  provider sandboxes (eSewa/Khalti test) and the mock NPI adapter only.
- **Never commit secrets.** No live API keys, merchant credentials, or
  keystores. Test credentials from providers' public docs only. `.env`
  files are git-ignored — keep it that way.
- **Payments code must be idempotent.** Any new payment path takes an
  idempotency key and proves a retry cannot double-charge.
- **Ledger stays double-entry.** Balances are derived from entries;
  don't introduce mutable balance fields.

## Making a change

1. Open an issue first for anything bigger than a typo, so we can agree
   on the approach.
2. Branch from `main`: `git checkout -b feat/short-description`.
3. Keep pull requests small and single-purpose. Explain *why*, not just
   *what*, in the PR description.
4. For app changes, run `flutter analyze` before pushing. For backend
   changes, start the server and exercise the endpoints you touched
   (show the commands/output in your PR).

## Reporting bugs

Use the bug report template. For anything security-related, follow
[SECURITY.md](SECURITY.md) instead of opening a public issue.
