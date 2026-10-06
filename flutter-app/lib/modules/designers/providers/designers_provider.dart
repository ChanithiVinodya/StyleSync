import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth/auth_provider.dart';
import '../models/designer_profile.dart';
import '../services/designers_service.dart';

final designersServiceProvider = Provider<DesignersService>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return DesignersService(apiClient);
});

final designersListProvider = FutureProvider<List<DesignerProfile>>((ref) async {
  final service = ref.read(designersServiceProvider);
  return service.getDesigners();
});

final designerProfileProvider = FutureProvider.family<DesignerProfile, String>((ref, id) async {
  final service = ref.read(designersServiceProvider);
  return service.getDesigner(id);
});
