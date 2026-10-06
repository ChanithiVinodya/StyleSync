import '../../../services/auth/api_client.dart';
import '../models/designer_profile.dart';

class DesignersService {
  final ApiClient _apiClient;

  DesignersService(this._apiClient);

  Future<List<DesignerProfile>> getDesigners() async {
    final response = await _apiClient.dio.get('/DesignerProfiles');
    return (response.data as List).map((json) => DesignerProfile.fromJson(json)).toList();
  }

  Future<DesignerProfile> getDesigner(String id) async {
    final response = await _apiClient.dio.get('/DesignerProfiles/$id');
    return DesignerProfile.fromJson(response.data);
  }

  Future<DesignerProfile> createDesigner(DesignerProfile profile) async {
    final response = await _apiClient.dio.post('/DesignerProfiles', data: profile.toJson());
    return DesignerProfile.fromJson(response.data);
  }

  Future<void> updateDesigner(String id, DesignerProfile profile) async {
    await _apiClient.dio.put('/DesignerProfiles/$id', data: profile.toJson());
  }

  Future<void> deleteDesigner(String id) async {
    await _apiClient.dio.delete('/DesignerProfiles/$id');
  }
}
