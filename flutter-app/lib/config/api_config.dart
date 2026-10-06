import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiConfig {
  // Production Cloud Backend on Render
  static const String cloudBackendUrl = 'https://stylesync-backend-a2yu.onrender.com/api';
  static const String serverHost = '10.253.20.14:5000';
  static const String _storageKey = 'stylesync_custom_base_url';
  static const _storage = FlutterSecureStorage();

  // Default to the live cloud backend so APK runs out-of-the-box on any device
  static String get defaultBaseUrl => cloudBackendUrl;

  static String baseUrl = defaultBaseUrl;

  static Future<void> loadSavedBaseUrl() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved != null && saved.trim().isNotEmpty) {
        baseUrl = saved.trim();
      }
    } catch (_) {}
  }

  static Future<void> updateBaseUrl(String newUrl) async {
    var formatted = newUrl.trim();
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'http://$formatted';
    }
    if (!formatted.endsWith('/api')) {
      formatted = formatted.endsWith('/') ? '${formatted}api' : '$formatted/api';
    }
    baseUrl = formatted;
    try {
      await _storage.write(key: _storageKey, value: baseUrl);
    } catch (_) {}
  }

  // Authentication endpoints
  static String get loginUrl => '$baseUrl/auth/login';
  static String get registerUrl => '$baseUrl/auth/register';
  static String get meUrl => '$baseUrl/auth/me';
}
