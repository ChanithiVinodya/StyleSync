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
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
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
          if (data['message'] != null && data['message'].toString().trim().isNotEmpty) {
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
          } else if (data['title'] != null && data['title'].toString().trim().isNotEmpty) {
            errorMessage = data['title'].toString();
          }
        } else if (data is String && data.trim().isNotEmpty) {
          errorMessage = data;
        }

        if (statusCode == 401) {
          return AuthException(
            message: errorMessage.contains('Invalid email or password')
                ? errorMessage
                : 'Invalid email or password. Please verify your credentials.',
            statusCode: 401,
            type: AuthErrorType.invalidCredentials,
          );
        } else if (statusCode == 409) {
          return AuthException(
            message: errorMessage.toLowerCase().contains('already')
                ? errorMessage
                : 'An account with this email address already exists. Please sign in instead.',
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
            message: 'Server error encountered. Please try again later.',
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
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.connectionError) {
          return const AuthException(
            message: 'Unable to connect to the StyleSync server. Please check your network connection.',
            type: AuthErrorType.networkError,
          );
        }

        final errStr = error.error?.toString() ?? error.message ?? '';
        if (errStr.toLowerCase().contains('socket') ||
            errStr.toLowerCase().contains('connection') ||
            errStr.toLowerCase().contains('network') ||
            errStr.toLowerCase().contains('xmlhttprequest')) {
          return const AuthException(
            message: 'Unable to connect to the server. Please verify your internet connection.',
            type: AuthErrorType.networkError,
          );
        }
      }
    }

    if (error is AuthException) {
      return error;
    }

    final raw = error?.toString() ?? '';
    if (raw.contains('CircularDependencyError') || raw.contains('DioException') || raw.contains('Exception:')) {
      return const AuthException(
        message: 'Registration request failed. Please check your connection and try again.',
        type: AuthErrorType.unknown,
      );
    }

    return AuthException(
      message: raw.isNotEmpty ? raw : 'An unexpected error occurred. Please try again.',
      type: AuthErrorType.unknown,
    );
  }
}
