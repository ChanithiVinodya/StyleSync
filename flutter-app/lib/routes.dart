import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth/auth_provider.dart';
import 'providers/auth/auth_state.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/designers/designer_profile_screen.dart';
import 'screens/requests/new_request_screen.dart';
import 'screens/quotes/quote_detail_screen.dart';
import 'screens/quotes/contract_status_screen.dart';
import 'modules/project_execution/project_execution_page.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/messages/messages_screen.dart';

/// Route guard that verifies active authentication before allowing access to protected screens.
/// If unauthenticated, it seamlessly redirects the user to the Login screen.
class AuthGuard extends ConsumerWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // If still resolving credentials on cold start, show clean unobtrusive background
    if (authState.status == AuthStatus.checking || authState.status == AuthStatus.initial) {
      return const Scaffold(
        backgroundColor: Color(0xFFEFE7DC),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8C4A3E)),
          ),
        ),
      );
    }

    // If unauthenticated, redirect to Login
    if (!authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
          );
        }
      });
      return const Scaffold(
        backgroundColor: Color(0xFFEFE7DC),
        body: SizedBox.shrink(),
      );
    }

    return child;
  }
}

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
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

    // Public Routes (No authentication required)
    if (uri.path == splash) {
      return MaterialPageRoute(builder: (_) => const SplashScreen());
    } else if (uri.path == login) {
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    } else if (uri.path == register) {
      return MaterialPageRoute(builder: (_) => const RegisterScreen());
    }

    // Protected Routes (Guarded by AuthGuard)
    if (uri.path == home) {
      return MaterialPageRoute(
        builder: (_) => const AuthGuard(child: HomeScreen(initialTab: 0)),
      );
    } else if (uri.path == designers) {
      return MaterialPageRoute(
        builder: (_) => const AuthGuard(child: HomeScreen(initialTab: 1)),
      );
    } else if (uri.path == requests) {
      return MaterialPageRoute(
        builder: (_) => const AuthGuard(child: HomeScreen(initialTab: 2)),
      );
    } else if (uri.path == newRequest) {
      return MaterialPageRoute(
        builder: (_) => const AuthGuard(child: NewRequestScreen()),
      );
    } else if (uri.path == profile) {
      return MaterialPageRoute(
        builder: (_) => const AuthGuard(child: ProfileScreen()),
      );
    } else if (uri.path == messages) {
      return MaterialPageRoute(
        builder: (_) => const AuthGuard(child: MessagesScreen()),
      );
    }

    // Protected Parameterized Routes
    final segments = uri.pathSegments;
    if (segments.length == 2 && segments[0] == 'designers') {
      return MaterialPageRoute(
        builder: (_) => AuthGuard(child: DesignerProfileScreen(id: segments[1])),
        settings: settings,
      );
    }
    if (segments.length == 2 && segments[0] == 'quotes') {
      return MaterialPageRoute(
        builder: (_) => AuthGuard(child: QuoteDetailScreen(id: segments[1])),
        settings: settings,
      );
    }
    if (segments.length == 2 && segments[0] == 'contracts') {
      return MaterialPageRoute(
        builder: (_) => AuthGuard(child: ContractStatusScreen(id: segments[1])),
        settings: settings,
      );
    }
    if (segments.length == 2 && segments[0] == 'progress') {
      return MaterialPageRoute(
        builder: (_) => AuthGuard(child: ProjectExecutionPage(projectId: segments[1])),
        settings: settings,
      );
    }

    // Default Fallback
    return MaterialPageRoute(
      builder: (_) => const AuthGuard(child: HomeScreen()),
    );
  }
}
