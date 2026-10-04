import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import 'auth_models.dart';
import 'token_storage_service.dart';

typedef UnauthorizedCallback = void Function();

class ApiClient {
  late final Dio dio;
  final TokenStorageService _tokenStorage;
  UnauthorizedCallback? onUnauthorized;

  ApiClient({
    required TokenStorageService tokenStorage,
    this.onUnauthorized,
    String? baseUrl,
  }) : _tokenStorage = tokenStorage {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            await _tokenStorage.clearAll();
            onUnauthorized?.call();
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Helper to convert DioException / server errors into typed AuthException
  static AuthException parseError(dynamic error) {
    if (error is DioException) {
      final response = error.response;
      if (response != null) {
        final statusCode = response.statusCode;
        final data = response.data;
        String errorMessage = 'An error occurred. Please try again.';

        if (data is Map<String, dynamic>) {
          if (data['message'] != null) {
            errorMessage = data['message'].toString();
          } else if (data['errors'] != null) {
            final errors = data['errors'];
            if (errors is Map) {
              final firstList = errors.values.firstWhere(
                (v) => v is List && v.isNotEmpty,
                orElse: () => null,
              );
              if (firstList != null && firstList.isNotEmpty) {
                errorMessage = firstList.first.toString();
              }
            } else if (errors is List && errors.isNotEmpty) {
              errorMessage = errors.first.toString();
            }
          } else if (data['title'] != null) {
            errorMessage = data['title'].toString();
          }
        } else if (data is String && data.isNotEmpty) {
          errorMessage = data;
        }

        if (statusCode == 401) {
          return AuthException(
            message: errorMessage.contains('Invalid email or password')
                ? errorMessage
                : 'Invalid email or password.',
            statusCode: 401,
            type: AuthErrorType.invalidCredentials,
          );
        } else if (statusCode == 409) {
          return AuthException(
            message: errorMessage.contains('already')
                ? errorMessage
                : 'Email address is already in use.',
            statusCode: 409,
            type: AuthErrorType.emailAlreadyInUse,
          );
        } else if (statusCode == 400) {
          return AuthException(
            message: errorMessage,
            statusCode: 400,
            type: AuthErrorType.validationError,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return AuthException(
            message: 'Server error. Please try again later.',
            statusCode: statusCode,
            type: AuthErrorType.serverError,
          );
        }

        return AuthException(
          message: errorMessage,
          statusCode: statusCode,
          type: AuthErrorType.unknown,
        );
      } else {
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionError) {
          return const AuthException(
            message: 'Unable to connect to the server. Please check your internet connection.',
            type: AuthErrorType.networkError,
          );
        }
      }
    }

    if (error is AuthException) {
      return error;
    }

    return AuthException(
      message: error?.toString() ?? 'An unexpected error occurred.',
      type: AuthErrorType.unknown,
    );
  }
}
