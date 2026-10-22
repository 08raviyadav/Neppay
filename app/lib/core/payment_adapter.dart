import 'dart:async';
import 'package:uuid/uuid.dart';

/// The seam between the app and the money rails.
///
/// V0 ships with [MockNpiAdapter] (in-app mock ledger with the same shape as
/// NCHL NPI) and a stub for wallet sandboxes. When the partner bank lands,
/// implement [PaymentAdapter] against real NPI/connectIPS and swap ONE line
/// in main.dart — the screens never change.
abstract class PaymentAdapter {
  Future<PayResult> payQr({
    required String merchantName,
    required String merchantId,
    required double amountNpr,
    required String idempotencyKey,
  });

  Future<PayResult> sendToVpa({
    required String vpa, // mobile number or handle
    required double amountNpr,
    required String idempotencyKey,
    String? note,
  });

  Future<String?> lookupName(String vpa); // name inquiry before send
  Future<double> balanceNpr();
  Future<List<Txn>> history();
}

class PayResult {
  final bool ok;
  final String txnId;
  final String message;
  const PayResult(this.ok, this.txnId, this.message);
}

class Txn {
  final String id;
  final String title;
  final double amountNpr; // negative = money out
  final DateTime at;
  const Txn(this.id, this.title, this.amountNpr, this.at);
}

String newIdempotencyKey() => const Uuid().v4();

/// In-memory mock of NPI-style rails: VPA transfers + QR acquires settle
/// instantly, balances move, and a repeated idempotency key returns the
/// ORIGINAL result instead of charging twice — the behaviour the real
/// backend ledger (../backend) enforces server-side.
class MockNpiAdapter implements PaymentAdapter {
  double _balance = 25430.00;
  final _txns = <Txn>[
    Txn('t3', 'NEA Bill Payment', -1840, DateTime.now().subtract(const Duration(days: 1))),
    Txn('t2', 'Received — Sita Sharma', 5000, DateTime.now().subtract(const Duration(days: 2))),
    Txn('t1', 'Bhatbhateni — FonePay QR', -1275, DateTime.now().subtract(const Duration(days: 3))),
  ];
  final _seenKeys = <String, PayResult>{};

  Future<void> _latency() => Future.delayed(const Duration(milliseconds: 450));

  @override
  Future<PayResult> payQr({
    required String merchantName,
    required String merchantId,
    required double amountNpr,
    required String idempotencyKey,
  }) async {
    if (_seenKeys.containsKey(idempotencyKey)) return _seenKeys[idempotencyKey]!;
    await _latency();
    if (amountNpr > _balance) {
      return const PayResult(false, '', 'Insufficient balance (mock)');
    }
    _balance -= amountNpr;
    final id = 'NPI${DateTime.now().millisecondsSinceEpoch}';
    _txns.insert(0, Txn(id, '$merchantName — QR', -amountNpr, DateTime.now()));
    final r = PayResult(true, id, 'Paid $merchantName');
    _seenKeys[idempotencyKey] = r;
    return r;
  }

  @override
  Future<PayResult> sendToVpa({
    required String vpa,
    required double amountNpr,
    required String idempotencyKey,
    String? note,
  }) async {
    if (_seenKeys.containsKey(idempotencyKey)) return _seenKeys[idempotencyKey]!;
    await _latency();
    if (amountNpr > _balance) {
      return const PayResult(false, '', 'Insufficient balance (mock)');
    }
    _balance -= amountNpr;
    final id = 'NPI${DateTime.now().millisecondsSinceEpoch}';
    _txns.insert(0, Txn(id, 'Sent to $vpa', -amountNpr, DateTime.now()));
    final r = PayResult(true, id, 'Sent to $vpa');
    _seenKeys[idempotencyKey] = r;
    return r;
  }

  @override
  Future<String?> lookupName(String vpa) async {
    await _latency();
    // Mock name inquiry — real NPI does this against the beneficiary bank.
    if (vpa.length >= 10) return 'R*** K*** (mock name inquiry)';
    return null;
  }

  @override
  Future<double> balanceNpr() async => _balance;

  @override
  Future<List<Txn>> history() async => List.unmodifiable(_txns);
}

/// Placeholder for eSewa/Khalti sandbox wiring (Flow 1, step 2).
/// Get test keys from the providers' developer docs (public test merchant
/// EPAYTEST for eSewa; Khalti test keys) — never commit live secrets.
class WalletSandboxConfig {
  static const esewaTestMerchant = 'EPAYTEST'; // public test merchant id
  static const esewaSandboxBase = 'https://uat.esewa.com.np/epay/main';
  static const khaltiSandboxBase = 'https://dev.khalti.com/api/v2/';
  const WalletSandboxConfig();
}
