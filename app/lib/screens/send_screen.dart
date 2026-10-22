import 'package:flutter/material.dart';
import '../core/payment_adapter.dart';

/// Flow 2 — Send to mobile / VPA (NEPALPAY Instant style).
/// Name inquiry runs BEFORE the confirm button enables: never send blind.
class SendScreen extends StatefulWidget {
  final PaymentAdapter adapter;
  const SendScreen({super.key, required this.adapter});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _vpa = TextEditingController();
  final _amount = TextEditingController();
  String? _name;
  bool _sending = false;

  Future<void> _lookup() async {
    final n = await widget.adapter.lookupName(_vpa.text.trim());
    setState(() => _name = n);
    if (n == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No account found for that number (mock)')));
    }
  }

  Future<void> _send() async {
    final amt = double.tryParse(_amount.text) ?? 0;
    if (amt <= 0) return;
    setState(() => _sending = true);
    final r = await widget.adapter.sendToVpa(
      vpa: _vpa.text.trim(),
      amountNpr: amt,
      idempotencyKey: newIdempotencyKey(),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.ok ? '✅ ${r.message} • ${r.txnId}' : '❌ ${r.message}')));
    if (r.ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Money')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _vpa,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Mobile number / VPA',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _lookup),
              ),
            ),
            if (_name != null)
              ListTile(leading: const Icon(Icons.verified), title: Text(_name!)),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  prefixText: 'रू ', labelText: 'Amount', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_name == null || _sending) ? null : _send,
                child: Text(_sending ? 'Sending…' : 'Send'),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Send unlocks only after the name check — no blind sends.'),
          ],
        ),
      ),
    );
  }
}
