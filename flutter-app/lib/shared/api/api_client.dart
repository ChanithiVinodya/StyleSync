import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth/token_storage_service.dart';

/// SHARED FILE - single place that knows the backend base URL.
/// Add module-specific request/response handling in your own module's
/// folder (e.g. lib/modules/designers/designers_api_service.dart), calling
/// through this client rather than duplicating base URL / header logic.
class ApiClient {
  ApiClient({String? baseUrl, TokenStorageService? tokenStorage})
      : _customBaseUrl = baseUrl,
        _tokenStorage = tokenStorage ?? TokenStorageService();

  final String? _customBaseUrl;
  String get baseUrl => _customBaseUrl ?? ApiConfig.baseUrl;
  final TokenStorageService _tokenStorage;
  String? authToken;

  Future<Map<String, String>> _getHeaders() async {
    final token = authToken ?? await _tokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path) async {
    final headers = await _getHeaders();
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: headers);
    return _decode(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    }
    throw Exception('API error ${res.statusCode}: ${res.body}');
  }
}
