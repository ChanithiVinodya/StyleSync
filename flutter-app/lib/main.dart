// State management: Riverpod for app-wide Auth & API state, with Provider for local client preferences

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'config/api_config.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.loadSavedBaseUrl();
  runApp(
    legacy_provider.MultiProvider(
      providers: [
        legacy_provider.ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: const ProviderScope(
        child: StyleSyncApp(),  
      ),
    ),
  );
}

/// Simple lightweight client state provider (ADR-aligned)
class AppStateProvider extends ChangeNotifier {
  String _clientName = 'Elena Vance';
  final String _clientEmail = 'elena.vance@designmail.com';
  ThemeMode _themeMode = ThemeMode.system;
  bool _biometricsEnabled = true;
  bool _quoteAlertsEnabled = true;
  bool _milestoneAlertsEnabled = true;
  bool _curatedInspoEnabled = false;

  String get clientName => _clientName;
  String get clientEmail => _clientEmail;
  ThemeMode get themeMode => _themeMode;
  bool get biometricsEnabled => _biometricsEnabled;
  bool get quoteAlertsEnabled => _quoteAlertsEnabled;
  bool get milestoneAlertsEnabled => _milestoneAlertsEnabled;
  bool get curatedInspoEnabled => _curatedInspoEnabled;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleBiometrics(bool val) {
    _biometricsEnabled = val;
    notifyListeners();
  }

  void toggleQuoteAlerts(bool val) {
    _quoteAlertsEnabled = val;
    notifyListeners();
  }

  void toggleMilestoneAlerts(bool val) {
    _milestoneAlertsEnabled = val;
    notifyListeners();
  }

  void toggleCuratedInspo(bool val) {
    _curatedInspoEnabled = val;
    notifyListeners();
  }

  void updateClientName(String name) {
    _clientName = name;
    notifyListeners();
  }
}

class StyleSyncApp extends StatelessWidget {
  const StyleSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = legacy_provider.Provider.of<AppStateProvider>(context);

    // StyleSync warm terracotta & organic architecture palette inspired by interior styling
    const primaryTerracotta = Color(0xFF8C4A3E);
    const deepEspresso = Color(0xFF241611);
    const canvasCream = Color(0xFFFAF7F2);

    // Dark Mode Palette: Web app matching (#12100E background, #1A1715 surface, #2E2824 border, #FAF8F5 text)
    const darkBg = Color(0xFF12100E);
    const darkSurface = Color(0xFF1A1715);
    const darkTerracotta = Color(0xFFD48270);
    const darkText = Color(0xFFFAF8F5);

    return MaterialApp(
      title: 'StyleSync',
      debugShowCheckedModeBanner: false,
      themeMode: appState.themeMode,
      // Light Theme
      theme: ThemeData(
        useMaterial3: true,
        splashFactory: InkRipple.splashFactory,
        brightness: Brightness.light,
        scaffoldBackgroundColor: canvasCream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryTerracotta,
          brightness: Brightness.light,
          primary: primaryTerracotta,
          surface: canvasCream,
          onSurface: deepEspresso,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: canvasCream,
          foregroundColor: deepEspresso,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: deepEspresso,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFEFE7DE)),
          ),
        ),
      ),
      // Dark Theme (Matches StyleSync Web App Dark Mode)
      darkTheme: ThemeData(
        useMaterial3: true,
        splashFactory: InkRipple.splashFactory,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: darkTerracotta,
          brightness: Brightness.dark,
          primary: darkTerracotta,
          surface: darkSurface,
          onSurface: darkText,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBg,
          foregroundColor: darkText,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: darkText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        cardTheme: CardThemeData(
          color: darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF2E2824)),
          ),
        ),
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
