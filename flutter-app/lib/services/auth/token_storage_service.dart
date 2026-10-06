import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_models.dart';

class TokenStorageService {
  final FlutterSecureStorage _storage;

  static const String _keyToken = 'stylesync_jwt_token';
  static const String _keyUser = 'stylesync_auth_user';
  static const String _keyRole = 'stylesync_auth_role';

  TokenStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveAuthData({
    required String token,
    required AuthUser user,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyUser, value: user.toJsonString());
    await _storage.write(key: _keyRole, value: user.role.displayName);
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _keyToken);
    } catch (_) {
      return null;
    }
  }

  Future<AuthUser?> getUser() async {
    try {
      final userJson = await _storage.read(key: _keyUser);
      if (userJson != null && userJson.isNotEmpty) {
        return AuthUser.fromJsonString(userJson);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getRole() async {
    try {
      return await _storage.read(key: _keyRole);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.delete(key: _keyToken);
      await _storage.delete(key: _keyUser);
      await _storage.delete(key: _keyRole);
    } catch (_) {
      // Best-effort cleanup
    }
  }
}
