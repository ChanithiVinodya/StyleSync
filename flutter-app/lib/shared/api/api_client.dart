import 'dart:convert';
import 'package:http/http.dart' as http;

/// SHARED FILE - single place that knows the backend base URL.
/// Add module-specific request/response handling in your own module's
/// folder (e.g. lib/modules/designers/designers_api.dart), calling
/// through this client rather than duplicating base URL / header logic.
class ApiClient {
  ApiClient({this.baseUrl = 'http://10.0.2.2:5000/api'});

  // 10.0.2.2 is the Android emulator's alias for the host machine's
  // localhost. Use http://localhost:5000/api for iOS simulator/web.
  final String baseUrl;
  String? authToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    return _decode(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
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
