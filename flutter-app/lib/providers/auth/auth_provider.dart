import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth/api_client.dart';
import '../../services/auth/auth_models.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/token_storage_service.dart';
import 'auth_state.dart';

/// Provider for persistent secure token & credentials storage
final tokenStorageProvider = Provider<TokenStorageService>((ref) {
  return TokenStorageService();
});

/// Shared ApiClient provider with Bearer token interceptor and 401 handler
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    tokenStorage: storage,
    onUnauthorized: () {
      // Defer execution outside Riverpod provider build graph to prevent circular dependency
      Future.microtask(() {
        try {
          ref.read(authProvider.notifier).handleUnauthorized();
        } catch (_) {}
      });
    },
  );
  return client;
});

/// Core AuthService provider for API operations
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient: apiClient);
});

/// Central Riverpod Notifier for managing app-wide authentication lifecycle
class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;
  late final TokenStorageService _tokenStorage;

  @override
  AuthState build() {
    _authService = ref.watch(authServiceProvider);
    _tokenStorage = ref.watch(tokenStorageProvider);
    // Check credentials asynchronously on initialization
    Future.microtask(() => checkAuthStatus());
    return AuthState.initial();
  }

  /// Check secure storage on startup and validate existing token with backend
  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.checking, clearError: true);
    try {
      final token = await _tokenStorage.getToken();
      final cachedUser = await _tokenStorage.getUser();

      if (token != null && token.isNotEmpty) {
        if (cachedUser != null) {
          // Immediately restore cached session for instant startup
          state = AuthState.authenticated(user: cachedUser, token: token);
        }

        // Validate or refresh profile with backend
        try {
          final serverUser = await _authService.getMe();
          await _tokenStorage.saveAuthData(token: token, user: serverUser);
          state = AuthState.authenticated(user: serverUser, token: token);
        } catch (e) {
          if (e is AuthException && e.statusCode == 401) {
            await _tokenStorage.clearAll();
            state = AuthState.unauthenticated();
          } else if (cachedUser == null) {
            // No cached user and network failed
            state = AuthState.unauthenticated();
          }
        }
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  /// Authenticate with email & password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      clearError: true,
    );

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      await _tokenStorage.saveAuthData(
        token: response.token,
        user: response.user,
      );

      state = AuthState.authenticated(
        user: response.user,
        token: response.token,
      );
      return true;
    } catch (e) {
      final error = ApiClient.parseError(e);
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: error.message,
      );
      return false;
    }
  }

  /// Register a new user (Client or Designer) and authenticate
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required UserRole role,
  }) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      clearError: true,
    );

    try {
      final response = await _authService.register(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        role: role,
      );

      await _tokenStorage.saveAuthData(
        token: response.token,
        user: response.user,
      );

      state = AuthState.authenticated(
        user: response.user,
        token: response.token,
      );
      return true;
    } catch (e) {
      final error = ApiClient.parseError(e);
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: error.message,
      );
      return false;
    }
  }

  /// Log out user, purge tokens, and notify all listeners
  Future<void> logout() async {
    await _tokenStorage.clearAll();
    state = AuthState.unauthenticated();
  }

  /// Handle automatic 401 unauthorized token expiry
  void handleUnauthorized() {
    state = AuthState.unauthenticated('Session expired. Please log in again.');
  }

  /// Clear transient error messages
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }
}

/// The primary auth provider exposed across the entire application
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Convenience provider for reading current authenticated user
final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authProvider).user;
});

/// Convenience provider for checking login status
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Convenience provider for checking role
final userRoleProvider = Provider<UserRole>((ref) {
  return ref.watch(authProvider).userRole;
});
