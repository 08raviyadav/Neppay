import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/payment_adapter.dart';

/// Flow 5 (history half) — unified, searchable history.
class HistoryScreen extends StatelessWidget {
  final PaymentAdapter adapter;
  const HistoryScreen({super.key, required this.adapter});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: FutureBuilder<List<Txn>>(
        future: adapter.history(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final txns = snap.data!;
          if (txns.isEmpty) return const Center(child: Text('No transactions yet'));
          return ListView.separated(
            itemCount: txns.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final t = txns[i];
              return ListTile(
                title: Text(t.title),
                subtitle: Text('${t.id} • ${DateFormat('MMM d, h:mm a').format(t.at)}'),
                trailing: Text(
                  '${t.amountNpr < 0 ? '−' : '+'} रू ${fmt.format(t.amountNpr.abs())}',
                  style: TextStyle(color: t.amountNpr < 0 ? null : Colors.green),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
