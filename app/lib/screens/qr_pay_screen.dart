import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/emv_qr.dart';
import '../core/payment_adapter.dart';

/// Flow 1 — Scan & Pay.
/// Camera scan → EMVCo parse (NEPALPAY / FonePay) → confirm sheet → MPIN →
/// adapter pay with an idempotency key. A demo payload button is included so
/// the flow can be tried on an emulator without a real QR.
class QrPayScreen extends StatefulWidget {
  final PaymentAdapter adapter;
  const QrPayScreen({super.key, required this.adapter});

  @override
  State<QrPayScreen> createState() => _QrPayScreenState();
}

class _QrPayScreenState extends State<QrPayScreen> {
  bool _handled = false;

  void _onPayload(String raw) {
    if (_handled) return;
    final qr = EmvQr.tryParse(raw);
    if (qr == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Not a NEPALPAY / FonePay QR')));
      return;
    }
    _handled = true;
    _showConfirm(qr);
  }

  Future<void> _showConfirm(EmvQr qr) async {
    final amountCtrl =
        TextEditingController(text: qr.amount?.toStringAsFixed(2) ?? '');
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(qr.merchantName ?? 'Merchant',
                style: Theme.of(ctx).textTheme.titleLarge),
            Text('${qr.scheme} QR • ${qr.merchantCity ?? ''}'),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !qr.isDynamic,
              decoration: const InputDecoration(
                  prefixText: 'रू ', labelText: 'Amount', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            const Text('Fee: रू 0.00 — shown plainly, no surprises.'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.pop(ctx, double.tryParse(amountCtrl.text) ?? 0),
                child: const Text('Pay'),
              ),
            ),
          ],
        ),
      ),
    );
    if (amount == null || amount <= 0 || !mounted) return;

    // One idempotency key per user intent: retries of THIS payment reuse it.
    final key = newIdempotencyKey();
    final sw = Stopwatch()..start();
    final r = await widget.adapter.payQr(
      merchantName: qr.merchantName ?? 'Merchant',
      merchantId: qr.merchantAccountId ?? 'unknown',
      amountNpr: amount,
      idempotencyKey: key,
    );
    sw.stop();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.ok
            ? '✅ ${r.message} • ${r.txnId} • ${sw.elapsedMilliseconds}ms'
            : '❌ ${r.message}')));
    if (r.ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan & Pay')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                final raw = capture.barcodes.firstOrNull?.rawValue;
                if (raw != null) _onPayload(raw);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton(
              onPressed: () {
                // Static FonePay-style demo payload (EMVCo TLV, no amount).
                _onPayload('00020101021138570010f1soft.com0111DEMO12345675204541153035245802NP5909DEMO MART6009KATHMANDU62290723DEMOREF1234567890126304ABCD');
              },
              child: const Text('Try demo QR (emulator)'),
            ),
          ),
        ],
      ),
    );
  }
}
