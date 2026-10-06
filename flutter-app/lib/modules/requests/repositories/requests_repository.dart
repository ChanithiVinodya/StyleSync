import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../services/auth/api_client.dart';
import '../models/request_models.dart';

class RequestsRepository {
  final ApiClient _apiClient;

  RequestsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  MediaType _determineMediaType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  ApiProblem _parseApiError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return ApiProblem.fromJson(data);
      }
    }
    return ApiProblem(
      title: e.toString(),
      status: 500,
    );
  }

  Future<RequestDetail> createDraft(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/requests', data: data);
      return RequestDetail.fromJson(response.data);
    } catch (e) {
      throw _parseApiError(e);
    }
  }

  Future<List<PalettePreset>> listPalettePresets() async {
    try {
      final response = await _apiClient.dio.get('/palettes/presets');
      return (response.data as List).map((e) => PalettePreset.fromJson(e)).toList();
    } catch (e) {
      throw _parseApiError(e);
    }
  }

  Future<List<PaletteColour>> generatePalette(String baseColour) async {
    try {
      final response = await _apiClient.dio.get(
        '/palettes/generate', 
        queryParameters: {'base': baseColour, 'baseColour': baseColour},
      );
      final data = response.data;
      if (data is List) {
        return data.map((e) => PaletteColour.fromJson(e as Map<String, dynamic>)).toList();
      } else if (data is Map<String, dynamic> && data['colours'] is List) {
        return (data['colours'] as List).map((e) => PaletteColour.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      throw _parseApiError(e);
    }
  }

  Future<RequestDetail> updateDraft(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/requests/$id', data: data);
      return RequestDetail.fromJson(response.data);
    } catch (e) {
      throw _parseApiError(e);
    }
  }

  Future<void> deleteDraft(String id) async {
    try {
      await _apiClient.dio.delete('/requests/$id');
    } catch (e) {
      throw _parseApiError(e);
    }
  }

  Future<RequestDetail> getRequest(String id) async {
    try {
      final response = await _apiClient.dio.get('/requests/$id');
      return RequestDetail.fromJson(response.data);
    } catch (e) {
      throw _parseApiError(e);
    }
  }

  Future<PagedResult<RequestSummary>> listRequests({Map<String, dynamic>? query}) async {
    try {
      final response = await _apiClient.dio.get('/requests', queryParameters: query);
      return PagedResult<RequestSummary>.fromJson(
        response.data, 
        (json) => RequestSummary.fromJson(json as Map<String, dynamic>)
      );
    } catch (e) {
      throw _parseApiError(e);
    }
  }

  Future<RequestDetail> uploadRoomPhoto(String id, String filePath, {List<int>? bytes, String? filename}) async {
    try {
      var name = filename ?? (filePath.isNotEmpty ? filePath.split(RegExp(r'[\\/]')).last : 'room_photo.jpg');
      if (!name.contains('.')) {
        name = '$name.jpg';
      }
      final contentType = _determineMediaType(name);
      final multipart = bytes != null
          ? MultipartFile.fromBytes(bytes, filename: name, contentType: contentType)
          : (kIsWeb
              ? throw UnsupportedError('File path upload is not supported on web without bytes.')
              : await MultipartFile.fromFile(filePath, filename: name, contentType: contentType));
      final formData = FormData.fromMap({
        'type': 'room',
        'files': [multipart],
      });
      await _apiClient.dio.post('/requests/$id/images', data: formData);
      return await getRequest(id);
    } catch (e) {
      throw _parseApiError(e);
    }
  }

  Future<RequestDetail> uploadMoodboard(String id, String filePath, {List<int>? bytes, String? filename}) async {
    try {
      var name = filename ?? (filePath.isNotEmpty ? filePath.split(RegExp(r'[\\/]')).last : 'moodboard.jpg');
      if (!name.contains('.')) {
        name = '$name.jpg';
      }
      final contentType = _determineMediaType(name);
      final multipart = bytes != null
          ? MultipartFile.fromBytes(bytes, filename: name, contentType: contentType)
          : (kIsWeb
              ? throw UnsupportedError('File path upload is not supported on web without bytes.')
              : await MultipartFile.fromFile(filePath, filename: name, contentType: contentType));
      final formData = FormData.fromMap({
        'type': 'moodboard',
        'files': [multipart],
      });
      await _apiClient.dio.post('/requests/$id/images', data: formData);
      return await getRequest(id);
    } catch (e) {
      throw _parseApiError(e);
    }
  }

  Future<RequestDetail> deleteImage(String id, String imageId) async {
    try {
      await _apiClient.dio.delete('/requests/$id/images/$imageId');
      return await getRequest(id);
    } catch (e) {
      throw _parseApiError(e);
    }
  }

  Future<void> submit(String id) async {
    try {
      await _apiClient.dio.post('/requests/$id/submit');
    } catch (e) {
      throw _parseApiError(e);
    }
  }
}
