import '../../services/auth/auth_models.dart';

enum AuthStatus {
  initial,
  checking,
  authenticated,
  unauthenticated,
  authenticating,
  error,
}

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? token;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.token,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null && token != null;
  bool get isLoading => status == AuthStatus.checking || status == AuthStatus.authenticating;
  bool get isClient => user?.role == UserRole.client;
  bool get isDesigner => user?.role == UserRole.designer;
  bool get isAdmin => user?.role == UserRole.admin;
  String get userName => user?.name ?? 'Guest Client';
  String get userEmail => user?.email ?? '';
  UserRole get userRole => user?.role ?? UserRole.client;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? token,
    String? errorMessage,
    bool clearError = false,
    bool clearAuth = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearAuth ? null : (user ?? this.user),
      token: clearAuth ? null : (token ?? this.token),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.checking() => const AuthState(status: AuthStatus.checking);
  factory AuthState.unauthenticated([String? errorMessage]) => AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: errorMessage,
      );
  factory AuthState.authenticated({
    required AuthUser user,
    required String token,
  }) =>
      AuthState(
        status: AuthStatus.authenticated,
        user: user,
        token: token,
      );
}
