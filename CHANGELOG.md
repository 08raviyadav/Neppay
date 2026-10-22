# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned
- MPIN + biometric confirmation gate before payments
- eSewa sandbox wired into the Scan & Pay flow
- Bills screen with mock billers (electricity, internet, mobile top-up)

## [0.1.0] - 2026-10-22

### Added
- Flutter app (Android first): Home, Scan & Pay, Send, Request & Split,
  History
- EMVCo QR parser with NEPALPAY / FonePay scheme detection
- `PaymentAdapter` interface with `MockNpiAdapter` (idempotent, instant
  settlement) — the seam where real NPI/connectIPS integration will land
- Send-money flow with name inquiry before the send action unlocks
- Node backend: double-entry ledger, idempotency-key enforcement on all
  payment endpoints, balance/history/lookup API
- Project docs: prototype plan, architecture notes, contributing guide,
  security policy
