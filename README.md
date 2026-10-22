<div align="center">

# NepPay

**A GPay-smooth payment app for Nepal — built in the open, on Nepal's own rails.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Flutter-blue)](https://flutter.dev)
[![Status](https://img.shields.io/badge/status-V0%20prototype-orange)](#-status)

Scan any **NEPALPAY QR** or **FonePay QR**, send money to any mobile number,
split bills with friends — one clean app instead of five clunky ones.

</div>

---

## ✨ Why NepPay?

Nepal already has the rails: NEPALPAY QR, FonePay, connectIPS and the National
Payment Interface (NPI). What it doesn't have is a front-end that feels like
Google Pay — fast, honest about fees, and impossible to double-charge.
NepPay is that front-end, developed as an open-source project.

## 🚀 Features (V0)

- **Scan & Pay** — real EMVCo QR parser for NEPALPAY + FonePay payloads,
  dynamic and static QR, fee shown plainly before you confirm
- **Send Money** — to any mobile number / VPA with **name inquiry first**;
  the send button stays locked until you see who you're paying
- **Request & Split** — payment requests and group bill-splitting
- **Unified History** — every transaction in one searchable list
- **No double charges, ever** — every payment carries an idempotency key;
  a retry returns the original result instead of charging again
- **Double-entry ledger backend** — balances are sums of ledger entries,
  never a mutable number that can silently drift

## 📱 Status

> **V0 prototype.** NepPay currently runs on public test environments
> (eSewa / Khalti sandboxes) and a mock NPI adapter. **No real money moves.**
> Live payments require a partner bank/PSP and an NRB payment service
> provider licence — see the [roadmap](PROTOTYPE_PLAN.md).
>
> This project is a technology prototype. It is **not** a licensed payment
> service and must not be used to move real funds.

## 🏗️ Architecture

```
Flutter app ──► PaymentAdapter (interface) ──► MockNpiAdapter (V0)
                                            ├─► Wallet sandboxes (eSewa/Khalti)
                                            └─► NPI / connectIPS (via partner, V1)
Backend (Node, zero deps) ──► double-entry ledger + idempotency store
```

The adapter seam is the whole trick: when a partner bank lands, the real
NPI adapter drops in behind the same interface — **no screen changes**.
Details in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## 🛠️ Quick start

**Backend** (Node 18+, no dependencies):

```bash
cd backend
node server.js          # http://localhost:8787
```

**App** (Flutter SDK required):

```bash
cd app
flutter pub get
flutter run             # Android device or emulator
```

Tap **"Try demo QR"** on the Scan screen to walk the full payment flow on
an emulator without a real QR code.

## 📂 Project structure

```
neppay/
├── app/            # Flutter app (Android first, one codebase)
│   └── lib/
│       ├── core/   # EMVCo QR parser, payment adapter seam
│       └── screens/# Home, Scan & Pay, Send, Request, History
├── backend/        # Node ledger service (idempotent payments API)
├── docs/           # Architecture notes
└── PROTOTYPE_PLAN.md
```

## 🤝 Contributing

Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) and our
[Code of Conduct](CODE_OF_CONDUCT.md). Found a security issue? Please read
[SECURITY.md](SECURITY.md) before opening a public issue.

## 📄 License

[MIT](LICENSE) © 2026 Ravi Yadav
