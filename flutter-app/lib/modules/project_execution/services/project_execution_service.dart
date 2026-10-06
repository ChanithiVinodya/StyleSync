import '../../../services/auth/api_client.dart';
import '../models/project_execution_models.dart';
import 'package:dio/dio.dart';

class ProjectExecutionService {
  final ApiClient _apiClient;

  ProjectExecutionService(this._apiClient);

  Future<List<Milestone>> getMilestones(String projectId) async {
    try {
      final response = await _apiClient.dio.get('/milestones?projectId=$projectId');
      if (response.data is List) {
        return (response.data as List).map((json) => Milestone.fromJson(json)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Task>> getTasks({String? milestoneId}) async {
    try {
      final query = milestoneId != null ? '?milestoneId=$milestoneId' : '';
      final response = await _apiClient.dio.get('/tasks$query');
      if (response.data is List) {
        return (response.data as List).map((json) => Task.fromJson(json)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<TaskDependency>> getTaskDependencies(String taskId) async {
    try {
      final response = await _apiClient.dio.get('/tasks/$taskId/dependencies');
      if (response.data is List) {
        return (response.data as List).map((json) => TaskDependency.fromJson(json)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<MaterialItem>> getMaterials(String projectId) async {
    try {
      final response = await _apiClient.dio.get('/materials?projectId=$projectId');
      if (response.data is List) {
        return (response.data as List).map((json) => MaterialItem.fromJson(json)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<ProgressPhoto>> getProgressPhotos(String projectId) async {
    try {
      final response = await _apiClient.dio.get('/progress-photos?projectId=$projectId');
      if (response.data is List) {
        return (response.data as List).map((json) => ProgressPhoto.fromJson(json)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<TimelineEvent>> getProjectTimeline(String projectId) async {
    try {
      final response = await _apiClient.dio.get('/projects/$projectId/timeline');
      if (response.data is List) {
        return (response.data as List).map((json) => TimelineEvent.fromJson(json)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<ProjectAnalytics> getProjectAnalytics(String projectId) async {
    try {
      final response = await _apiClient.dio.get('/projects/$projectId/analytics');
      if (response.data is Map<String, dynamic>) {
        return ProjectAnalytics.fromJson(response.data);
      }
      return ProjectAnalytics(
        overallProgress: 0.0,
        totalTasks: 0,
        completedTasks: 0,
        delayedTasks: 0,
        totalMilestones: 0,
        completedMilestones: 0,
        delayedMilestones: 0,
      );
    } catch (_) {
      return ProjectAnalytics(
        overallProgress: 0.0,
        totalTasks: 0,
        completedTasks: 0,
        delayedTasks: 0,
        totalMilestones: 0,
        completedMilestones: 0,
        delayedMilestones: 0,
      );
    }
  }
  // --- MILESTONES ---
  Future<Milestone> createMilestone(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/milestones', data: data);
    return Milestone.fromJson(response.data);
  }

  Future<Milestone> updateMilestone(String milestoneId, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/milestones/$milestoneId', data: data);
    return Milestone.fromJson(response.data);
  }

  Future<void> deleteMilestone(String milestoneId) async {
    await _apiClient.dio.delete('/milestones/$milestoneId');
  }

  // --- TASKS ---
  Future<Task> createTask(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/tasks', data: data);
    return Task.fromJson(response.data);
  }

  Future<Task> updateTask(String taskId, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/tasks/$taskId', data: data);
    return Task.fromJson(response.data);
  }

  Future<void> deleteTask(String taskId) async {
    await _apiClient.dio.delete('/tasks/$taskId');
  }

  // --- MATERIALS ---
  Future<MaterialItem> createMaterial(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/materials', data: data);
    return MaterialItem.fromJson(response.data);
  }

  Future<MaterialItem> updateMaterial(String materialId, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/materials/$materialId', data: data);
    return MaterialItem.fromJson(response.data);
  }

  Future<MaterialItem> updateMaterialStatus(String materialId, String status) async {
    final response = await _apiClient.dio.patch('/materials/$materialId/status', data: {'status': status});
    return MaterialItem.fromJson(response.data);
  }

  Future<void> deleteMaterial(String materialId) async {
    await _apiClient.dio.delete('/materials/$materialId');
  }

  // --- PROGRESS PHOTOS ---
  Future<ProgressPhoto> createProgressPhoto(FormData data) async {
    final response = await _apiClient.dio.post('/progress-photos', data: data);
    return ProgressPhoto.fromJson(response.data);
  }

  Future<ProgressPhoto> updateProgressPhoto(String photoId, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/progress-photos/$photoId', data: data);
    return ProgressPhoto.fromJson(response.data);
  }

  Future<void> deleteProgressPhoto(String photoId) async {
    await _apiClient.dio.delete('/progress-photos/$photoId');
  }

  // --- TIMELINE EVENTS ---
  Future<TimelineEvent> createTimelineEvent(String projectId, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/projects/$projectId/timeline', data: data);
    return TimelineEvent.fromJson(response.data);
  }

  Future<TimelineEvent> updateTimelineEvent(String projectId, String eventId, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/projects/$projectId/timeline/$eventId', data: data);
    return TimelineEvent.fromJson(response.data);
  }

  Future<void> deleteTimelineEvent(String projectId, String eventId) async {
    await _apiClient.dio.delete('/projects/$projectId/timeline/$eventId');
  }
}
