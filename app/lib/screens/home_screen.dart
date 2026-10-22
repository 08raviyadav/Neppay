import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/payment_adapter.dart';
import 'qr_pay_screen.dart';
import 'send_screen.dart';
import 'request_screen.dart';

class HomeScreen extends StatefulWidget {
  final PaymentAdapter adapter;
  const HomeScreen({super.key, required this.adapter});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double? _balance;
  List<Txn> _recent = [];
  final _fmt = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final b = await widget.adapter.balanceNpr();
    final h = await widget.adapter.history();
    if (!mounted) return;
    setState(() {
      _balance = b;
      _recent = h.take(3).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NepPay'), centerTitle: false),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total balance (mock)'),
                    const SizedBox(height: 6),
                    Text(
                      _balance == null ? '—' : 'रू ${_fmt.format(_balance)}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Text('Linked bank •••4821 — connectIPS style (mock)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Action(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan & Pay',
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => QrPayScreen(adapter: widget.adapter)));
                    _load();
                  },
                ),
                _Action(
                  icon: Icons.send,
                  label: 'Send',
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => SendScreen(adapter: widget.adapter)));
                    _load();
                  },
                ),
                _Action(
                  icon: Icons.request_page,
                  label: 'Request',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RequestScreen())),
                ),
                const _Action(icon: Icons.receipt_long, label: 'Bills'),
              ],
            ),
            const SizedBox(height: 24),
            Text('Recent', style: Theme.of(context).textTheme.titleMedium),
            ..._recent.map((t) => ListTile(
                  title: Text(t.title),
                  subtitle: Text(DateFormat('MMM d, h:mm a').format(t.at)),
                  trailing: Text(
                    '${t.amountNpr < 0 ? '−' : '+'} रू ${_fmt.format(t.amountNpr.abs())}',
                    style: TextStyle(color: t.amountNpr < 0 ? null : Colors.green),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _Action({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: CircleAvatar(radius: 28, child: Icon(icon)),
        ),
        const SizedBox(height: 6),
        Text(label),
      ],
    );
  }
}
