import 'package:flutter/material.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/designers/designer_profile_screen.dart';
import 'screens/requests/new_request_screen.dart';
import 'screens/quotes/quote_detail_screen.dart';
import 'screens/quotes/contract_status_screen.dart';
import 'screens/progress/project_timeline_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/messages/messages_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/';
  static const String designers = '/designers';
  static const String designerProfile = '/designers/:id';
  static const String newRequest = '/requests/new';
  static const String requests = '/requests';
  static const String quoteDetail = '/quotes/:id';
  static const String contractStatus = '/contracts/:id';
  static const String progress = '/progress/:projectId';
  static const String profile = '/profile';
  static const String messages = '/messages';

  /// Helper to generate parameterized route strings
  static String designerProfilePath(String id) => '/designers/$id';
  static String quoteDetailPath(String id) => '/quotes/$id';
  static String contractStatusPath(String id) => '/contracts/$id';
  static String progressPath(String projectId) => '/progress/$projectId';

  /// Central Route Generator handling static and parameterized routes
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');

    // Handle exact named routes
    if (uri.path == splash) {
      return MaterialPageRoute(
        builder: (context) => SplashScreen(
          onEnter: () => Navigator.of(context).pushReplacementNamed(home),
          onSkip: () => Navigator.of(context).pushReplacementNamed(home),
        ),
      );
    } else if (uri.path == home) {
      return MaterialPageRoute(builder: (_) => const HomeScreen(initialTab: 0));
    } else if (uri.path == designers) {
      return MaterialPageRoute(builder: (_) => const HomeScreen(initialTab: 1));
    } else if (uri.path == requests) {
      return MaterialPageRoute(builder: (_) => const HomeScreen(initialTab: 2));
    } else if (uri.path == newRequest) {
      return MaterialPageRoute(builder: (_) => const NewRequestScreen());
    } else if (uri.path == profile) {
      return MaterialPageRoute(builder: (_) => const ProfileScreen());
    } else if (uri.path == messages) {
      return MaterialPageRoute(builder: (_) => const MessagesScreen());
    }

    // Handle parameterized routes
    final segments = uri.pathSegments;
    if (segments.length == 2 && segments[0] == 'designers') {
      return MaterialPageRoute(
        builder: (_) => DesignerProfileScreen(id: segments[1]),
        settings: settings,
      );
    }
    if (segments.length == 2 && segments[0] == 'quotes') {
      return MaterialPageRoute(
        builder: (_) => QuoteDetailScreen(id: segments[1]),
        settings: settings,
      );
    }
    if (segments.length == 2 && segments[0] == 'contracts') {
      return MaterialPageRoute(
        builder: (_) => ContractStatusScreen(id: segments[1]),
        settings: settings,
      );
    }
    if (segments.length == 2 && segments[0] == 'progress') {
      return MaterialPageRoute(
        builder: (_) => ProjectTimelineScreen(projectId: segments[1]),
        settings: settings,
      );
    }

    // Default fallback
    return MaterialPageRoute(builder: (_) => const HomeScreen());
  }
}
