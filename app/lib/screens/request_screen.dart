import 'package:flutter/material.dart';

/// Flow 3 — Request money + split bill (UI shell, V0).
/// Requests are internal to our ledger until real Request-to-Pay (NPI)
/// arrives via the partner adapter.
class RequestScreen extends StatelessWidget {
  const RequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request & Split')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: Icon(Icons.request_page),
            title: Text('Request money'),
            subtitle: Text('Send a payment request to any mobile number'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.group),
            title: Text('Split a bill'),
            subtitle: Text('Dinner, rent, group gifts — split equally or custom'),
          ),
          const Divider(),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pending requests', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('No pending requests (mock inbox).'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
