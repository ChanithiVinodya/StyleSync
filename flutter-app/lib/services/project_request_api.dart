import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project_request.dart';
import '../models/style_analysis_result.dart';

class ProjectRequestApiService {
  static const String baseUrl = 'http://localhost:5000/api/v1/requests';

  // JWT Token setter if needed for client authentication
  static String? authToken;

  Map<String, String> _headers() {
    final headers = {'Content-Type': 'application/json'};
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  Future<List<ProjectRequestModel>> fetchAllRequests({
    String? search,
    String? status,
    String? roomType,
    String? sortBy,
    int page = 1,
    int pageSize = 20,
  }) async {
    final Map<String, String> params = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null && status.isNotEmpty && status != 'All') params['status'] = status;
    if (roomType != null && roomType.isNotEmpty && roomType != 'All') params['roomType'] = roomType;
    if (sortBy != null && sortBy.isNotEmpty) params['sortBy'] = sortBy;

    final uri = Uri.parse(baseUrl).replace(queryParameters: params);

    try {
      final response = await http.get(uri, headers: _headers());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data is Map ? (data['items'] ?? []) : (data is List ? data : []);
        return items.map((json) => ProjectRequestModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('API fetch notice, returning fallback list: $e');
    }
    return _getFallbackRequests();
  }

  Future<ProjectRequestModel> fetchRequestById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'), headers: _headers());
      if (response.statusCode == 200) {
        return ProjectRequestModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Fetch by ID notice: $e');
    }
    final fallback = _getFallbackRequests();
    return fallback.firstWhere((r) => r.id == id, orElse: () => fallback.first);
  }

  Future<ProjectRequestModel> createProjectRequest({
    required String roomType,
    required double roomSize,
    required double budgetLkr,
    required List<String> preferredColours,
    required List<String> preferredStyles,
    required String description,
    required List<String> photoUrls,
    required bool submitImmediately,
  }) async {
    final payload = {
      'title': '$roomType Makeover',
      'description': description,
      'roomType': roomType,
      'roomSize': roomSize,
      'budgetMin': budgetLkr,
      'budgetMax': budgetLkr,
      'preferredColours': preferredColours.join(', '),
      'stylePreferences': preferredStyles.join(', '),
      'specialRequirements': 'Dimensions: ${roomSize.toStringAsFixed(0)} sq ft',
      'images': photoUrls.map((url) => {'imageUrl': url, 'imageType': photoUrls.indexOf(url) == 0 ? 'RoomPhoto' : 'Moodboard'}).toList(),
      'submitImmediately': submitImmediately,
    };

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: _headers(),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ProjectRequestModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Create request notice: $e');
    }

    // Return client model if server offline
    return ProjectRequestModel(
      id: 'req-${DateTime.now().millisecondsSinceEpoch}',
      clientId: 'client-1',
      title: '$roomType Makeover',
      roomType: roomType,
      roomSize: roomSize,
      lengthFeet: 15,
      widthFeet: 10,
      heightFeet: 9,
      budgetLkr: budgetLkr,
      preferredStyles: preferredStyles,
      preferredColours: preferredColours,
      description: description,
      status: submitImmediately ? 'AIAnalysis' : 'Draft',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      photos: photoUrls.map((url) => ProjectRequestPhotoModel(
        id: 'img-${photoUrls.indexOf(url)}',
        photoUrl: url,
        imageType: photoUrls.indexOf(url) == 0 ? 'RoomPhoto' : 'Moodboard',
        storageKey: url,
        uploadedAt: DateTime.now(),
      )).toList(),
      suggestedPalette: [
        ColorPaletteChip(hexCode: '#F4F1EA', colorName: 'Warm White'),
        ColorPaletteChip(hexCode: '#C2A68C', colorName: 'Oatmeal'),
        ColorPaletteChip(hexCode: '#2C3E50', colorName: 'Midnight Navy'),
        ColorPaletteChip(hexCode: '#8C9A86', colorName: 'Sage Green'),
      ],
      statusHistory: [
        StatusHistoryItem(
          status: submitImmediately ? 'AIAnalysis' : 'Draft',
          reason: submitImmediately ? 'Submitted to AI analysis' : 'Draft created',
          changedBy: 'Client User',
          createdAt: DateTime.now(),
        )
      ],
    );
  }

  Future<ProjectRequestModel> updateProjectRequest(String id, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: _headers(),
        body: jsonEncode(updates),
      );
      if (response.statusCode == 200) {
        return ProjectRequestModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Update draft notice: $e');
    }
    return fetchRequestById(id);
  }

  Future<bool> deleteProjectRequest(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'), headers: _headers());
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Delete draft notice: $e');
      return true;
    }
  }

  Future<ProjectRequestModel> submitRequestForAIAnalysis(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$id/submit'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        return ProjectRequestModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Submit for AI analysis notice: $e');
    }
    return fetchRequestById(id);
  }

  List<ProjectRequestModel> _getFallbackRequests() {
    return [
      ProjectRequestModel(
        id: '1',
        clientId: 'client-1',
        title: 'Master Bedroom Redesign',
        roomType: 'Bedroom',
        roomSize: 180.0,
        lengthFeet: 15,
        widthFeet: 12,
        heightFeet: 10,
        budgetLkr: 250000.0,
        preferredStyles: ['Modern', 'Minimalist'],
        preferredColours: ['#F4F1EA', '#C2A68C', '#2C3E50'],
        description: 'I want a serene, cozy master bedroom with soft natural lighting and minimalist furniture.',
        status: 'ProposalReady',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
        photos: [
          ProjectRequestPhotoModel(
            id: 'photo-1',
            photoUrl: 'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?q=80&w=800&auto=format&fit=crop',
            imageType: 'RoomPhoto',
            storageKey: 'sample/bedroom-1.jpg',
            uploadedAt: DateTime.now(),
          ),
          ProjectRequestPhotoModel(
            id: 'photo-2',
            photoUrl: 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?q=80&w=800&auto=format&fit=crop',
            imageType: 'Moodboard',
            storageKey: 'sample/bedroom-2.jpg',
            uploadedAt: DateTime.now(),
          ),
        ],
        suggestedPalette: [
          ColorPaletteChip(hexCode: '#F4F1EA', colorName: 'Warm White'),
          ColorPaletteChip(hexCode: '#C2A68C', colorName: 'Oatmeal'),
          ColorPaletteChip(hexCode: '#2C3E50', colorName: 'Midnight Navy'),
          ColorPaletteChip(hexCode: '#8C9A86', colorName: 'Sage Green'),
        ],
        statusHistory: [
          StatusHistoryItem(status: 'Draft', reason: 'Created draft', changedBy: 'Client', createdAt: DateTime.now().subtract(const Duration(days: 2))),
          StatusHistoryItem(status: 'Submitted', reason: 'Validation passed', changedBy: 'Client', createdAt: DateTime.now().subtract(const Duration(days: 2))),
          StatusHistoryItem(status: 'AIAnalysis', reason: 'Extracted style features', changedBy: 'AI Agent', createdAt: DateTime.now().subtract(const Duration(days: 1))),
          StatusHistoryItem(status: 'ProposalReady', reason: 'Design proposal generated', changedBy: 'System', createdAt: DateTime.now()),
        ],
      ),
    ];
  }
}
