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
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF12100E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC48A36),
          secondary: Color(0xFFD97706),
          surface: Color(0xFF1A1715),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF161411),
          indicatorColor: const Color(0xFF2E2721),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: Color(0xFFE8A849), fontSize: 12, fontWeight: FontWeight.w600);
            }
            return const TextStyle(color: Color(0xFFA8A29E), fontSize: 12);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFFE8A849));
            }
            return const IconThemeData(color: Color(0xFFA8A29E));
          }),
        ),
        useMaterial3: true,
      ),
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
  // Set default tab to Quotes & Contracts (Student 3) for immediate preview
  int _index = 2;

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
      backgroundColor: const Color(0xFF12100E),
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
