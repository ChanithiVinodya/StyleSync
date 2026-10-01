import 'package:flutter_test/flutter_test.dart';
import 'package:stylesync/services/auth/auth_models.dart';

void main() {
  group('UserRole & AuthModels Tests', () {
    test('UserRole parsing correctly resolves Client, Designer, and Admin', () {
      expect(UserRole.fromString('Client'), equals(UserRole.client));
      expect(UserRole.fromString('client'), equals(UserRole.client));
      expect(UserRole.fromString('0'), equals(UserRole.client));

      expect(UserRole.fromString('Designer'), equals(UserRole.designer));
      expect(UserRole.fromString('designer'), equals(UserRole.designer));
      expect(UserRole.fromString('1'), equals(UserRole.designer));

      expect(UserRole.fromString('Admin'), equals(UserRole.admin));
      expect(UserRole.fromString('admin'), equals(UserRole.admin));
      expect(UserRole.fromString('2'), equals(UserRole.admin));

      expect(UserRole.fromString(null), equals(UserRole.client));
      expect(UserRole.fromString('unknown_value'), equals(UserRole.client));
    });

    test('AuthUser serialization and deserialization from JSON', () {
      final json = {
        'id': 'user-123',
        'name': 'Elena Vance',
        'email': 'elena@stylesync.com',
        'role': 'Client',
        'isActive': true,
      };

      final user = AuthUser.fromJson(json);
      expect(user.id, equals('user-123'));
      expect(user.name, equals('Elena Vance'));
      expect(user.email, equals('elena@stylesync.com'));
      expect(user.role, equals(UserRole.client));
      expect(user.isActive, isTrue);

      final serialized = user.toJson();
      expect(serialized['id'], equals('user-123'));
      expect(serialized['name'], equals('Elena Vance'));
      expect(serialized['email'], equals('elena@stylesync.com'));
      expect(serialized['role'], equals('Client'));
    });

    test('AuthResponse parses nested user and JWT token payload', () {
      final json = {
        'token': 'mock-jwt-token-xyz',
        'expiresAt': '2026-12-31T23:59:59Z',
        'user': {
          'id': 'des-456',
          'name': 'Julian Thorne',
          'email': 'julian@atelier.com',
          'role': 'Designer',
          'isActive': true,
        },
      };

      final response = AuthResponse.fromJson(json);
      expect(response.token, equals('mock-jwt-token-xyz'));
      expect(response.user.name, equals('Julian Thorne'));
      expect(response.user.role, equals(UserRole.designer));
    });

    test('AuthException retains error type and status code', () {
      const exception = AuthException(
        message: 'Invalid email or password.',
        statusCode: 401,
        type: AuthErrorType.invalidCredentials,
      );

      expect(exception.message, equals('Invalid email or password.'));
      expect(exception.statusCode, equals(401));
      expect(exception.type, equals(AuthErrorType.invalidCredentials));
      expect(exception.toString(), equals('Invalid email or password.'));
    });
  });
}
