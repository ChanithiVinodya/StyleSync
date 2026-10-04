import '../../config/api_config.dart';
import 'api_client.dart';
import 'auth_models.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.loginUrl,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return AuthResponse.fromJson(data);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required UserRole role,
  }) async {
    try {
      final registerResponse = await _apiClient.dio.post(
        ApiConfig.registerUrl,
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'confirmPassword': confirmPassword,
          'role': role.displayName,
        },
      );

      final data = registerResponse.data;
      if (data is Map<String, dynamic> && data.containsKey('token')) {
        return AuthResponse.fromJson(data);
      }

      // Backend returns UserResponse on registration; perform seamless login to get JWT
      return await login(email: email, password: password);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<AuthUser> getMe() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.meUrl);
      final data = response.data as Map<String, dynamic>;
      return AuthUser.fromJson(data);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }
}
