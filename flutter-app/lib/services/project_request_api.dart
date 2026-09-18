import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project_request.dart';
import '../models/style_analysis_result.dart';

class ProjectRequestApiService {
  static const String baseUrl = 'http://localhost:5000/api/v1/project-requests';
  static const String clientIdHeader = 'client-nimali';

  Future<List<ProjectRequestModel>> fetchAllRequests({String? status}) async {
    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      if (status != null) 'status': status,
      'clientId': clientIdHeader,
    });

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ProjectRequestModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load project requests');
    }
  }

  Future<ProjectRequestModel> fetchRequestById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    if (response.statusCode == 200) {
      return ProjectRequestModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load project request details');
    }
  }

  Future<ProjectRequestModel> createProjectRequest({
    required String roomType,
    required double lengthFeet,
    required double widthFeet,
    required double heightFeet,
    required double budgetLkr,
    required List<String> preferredStyles,
    required String description,
    required bool submitImmediately,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-Client-Id': clientIdHeader,
      },
      body: jsonEncode({
        'roomType': roomType,
        'lengthFeet': lengthFeet,
        'widthFeet': widthFeet,
        'heightFeet': heightFeet,
        'budgetLkr': budgetLkr,
        'preferredStyles': preferredStyles,
        'description': description,
        'submitImmediately': submitImmediately,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return ProjectRequestModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create project request');
    }
  }

  Future<ProjectRequestModel> submitRequestForAIAnalysis(String id) async {
    final response = await http.post(Uri.parse('$baseUrl/$id/submit'));
    if (response.statusCode == 200) {
      return ProjectRequestModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to submit request for AI Analysis');
    }
  }

  Future<StyleAnalysisResultModel> fetchStyleAnalysis(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id/style-analysis'));
    if (response.statusCode == 200) {
      return StyleAnalysisResultModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch style analysis result');
    }
  }
}
