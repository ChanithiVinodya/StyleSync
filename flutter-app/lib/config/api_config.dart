import 'package:flutter/foundation.dart';

class ApiConfig {
  // Configurable base URL:
  // Android Emulator uses 10.0.2.2 to access host localhost
  // Web, macOS, Windows, iOS simulator use localhost
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://localhost:5000/api';
    }
  }

  static String baseUrl = defaultBaseUrl;

  // Authentication endpoints
  static String get loginUrl => '$baseUrl/auth/login';
  static String get registerUrl => '$baseUrl/auth/register';
  static String get meUrl => '$baseUrl/auth/me';
}
