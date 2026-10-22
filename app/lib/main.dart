import 'package:flutter/material.dart';
import 'core/payment_adapter.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';

/// NepPay — V0 prototype (Path A).
/// Swap MockNpiAdapter for the real NPI adapter when the partner bank lands;
/// nothing else in the app changes.
void main() {
  final PaymentAdapter adapter = MockNpiAdapter();
  runApp(NepPayApp(adapter: adapter));
}

class NepPayApp extends StatelessWidget {
  final PaymentAdapter adapter;
  const NepPayApp({super.key, required this.adapter});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NepPay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E4F)),
        useMaterial3: true,
      ),
      home: _Shell(adapter: adapter),
    );
  }
}

class _Shell extends StatefulWidget {
  final PaymentAdapter adapter;
  const _Shell({required this.adapter});

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(adapter: widget.adapter),
      HistoryScreen(adapter: widget.adapter),
    ];
    return Scaffold(
      body: pages[_i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}
