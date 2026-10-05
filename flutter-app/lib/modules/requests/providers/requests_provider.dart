import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth/auth_provider.dart';
import '../repositories/requests_repository.dart';
import '../models/request_models.dart';

final requestsRepositoryProvider = Provider<RequestsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RequestsRepository(apiClient: apiClient);
});

// A simple provider for listing requests with queries
final requestsListProvider = FutureProvider.family<PagedResult<RequestSummary>, Map<String, dynamic>?>((ref, query) async {
  final repo = ref.watch(requestsRepositoryProvider);
  return repo.listRequests(query: query);
});

// A provider for getting a single request
final requestDetailProvider = FutureProvider.family<RequestDetail, String>((ref, id) async {
  final repo = ref.watch(requestsRepositoryProvider);
  return repo.getRequest(id);
});
