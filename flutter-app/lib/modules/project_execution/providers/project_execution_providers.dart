import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth/auth_provider.dart';
import '../services/project_execution_service.dart';
import '../models/project_execution_models.dart';

final projectExecutionServiceProvider = Provider<ProjectExecutionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProjectExecutionService(apiClient);
});

final projectMilestonesProvider = FutureProvider.family<List<Milestone>, String>((ref, projectId) async {
  final service = ref.watch(projectExecutionServiceProvider);
  return service.getMilestones(projectId);
});

final projectTasksProvider = FutureProvider.family<List<Task>, String?>((ref, milestoneId) async {
  final service = ref.watch(projectExecutionServiceProvider);
  return service.getTasks(milestoneId: milestoneId);
});

final projectMaterialsProvider = FutureProvider.family<List<MaterialItem>, String>((ref, projectId) async {
  final service = ref.watch(projectExecutionServiceProvider);
  return service.getMaterials(projectId);
});

final projectTimelineProvider = FutureProvider.family<List<TimelineEvent>, String>((ref, projectId) async {
  final service = ref.watch(projectExecutionServiceProvider);
  return service.getProjectTimeline(projectId);
});

final projectAnalyticsProvider = FutureProvider.family<ProjectAnalytics, String>((ref, projectId) async {
  final service = ref.watch(projectExecutionServiceProvider);
  return service.getProjectAnalytics(projectId);
});
