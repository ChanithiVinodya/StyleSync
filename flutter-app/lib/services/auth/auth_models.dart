import 'dart:convert';

enum UserRole {
  client,
  designer,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.client:
        return 'Client';
      case UserRole.designer:
        return 'Designer';
      case UserRole.admin:
        return 'Admin';
    }
  }

  int get backendValue {
    switch (this) {
      case UserRole.client:
        return 0;
      case UserRole.designer:
        return 1;
      case UserRole.admin:
        return 2;
    }
  }

  static UserRole fromString(String? value) {
    if (value == null) return UserRole.client;
    final normalized = value.trim().toLowerCase();
    if (normalized == 'designer' || normalized == '1') return UserRole.designer;
    if (normalized == 'admin' || normalized == '2') return UserRole.admin;
    return UserRole.client;
  }
}

class AuthUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: UserRole.fromString(json['role']?.toString()),
      isActive: json['isActive'] == true || json['isActive'] == null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.displayName,
      'isActive': isActive,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory AuthUser.fromJsonString(String jsonString) {
    return AuthUser.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}

class AuthResponse {
  final String token;
  final DateTime expiresAt;
  final AuthUser user;

  const AuthResponse({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token']?.toString() ?? '',
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString()) ?? DateTime.now().add(const Duration(days: 7))
          : DateTime.now().add(const Duration(days: 7)),
      user: json['user'] != null
          ? AuthUser.fromJson(json['user'] as Map<String, dynamic>)
          : AuthUser.fromJson(json),
    );
  }
}

enum AuthErrorType {
  invalidCredentials,
  emailAlreadyInUse,
  validationError,
  networkError,
  unauthorized,
  serverError,
  unknown,
}

class AuthException implements Exception {
  final String message;
  final int? statusCode;
  final AuthErrorType type;

  const AuthException({
    required this.message,
    this.statusCode,
    this.type = AuthErrorType.unknown,
  });

  @override
  String toString() => message;
}
