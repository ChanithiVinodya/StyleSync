import 'package:flutter/material.dart';
import 'modules/designers/designers_page.dart';
import 'modules/project_requests/project_requests_page.dart';
import 'modules/quotes_contracts/quotes_contracts_page.dart';
import 'modules/project_execution/project_execution_page.dart';

void main() {
  runApp(const StyleSyncApp());
}

class StyleSyncApp extends StatelessWidget {
  const StyleSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StyleSync',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  // Each tab is owned by a different student - see module comments.
  static const _pages = [
    ProjectRequestsPage(), // Student 2 - primary client-facing flow
    DesignersPage(), // Student 1
    QuotesContractsPage(), // Student 3
    ProjectExecutionPage(), // Student 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.add_home), label: 'Request'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Designers'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Quotes'),
          NavigationDestination(icon: Icon(Icons.timeline), label: 'Progress'),
        ],
      ),
    );
  }
}
