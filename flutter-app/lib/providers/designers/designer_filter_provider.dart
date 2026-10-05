import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../modules/designers/models/designer_summary.dart';

/// Riverpod Notifier managing active query and filter parameters for the designer directory.
class DesignerFilterNotifier extends Notifier<DesignerQueryParameters> {
  @override
  DesignerQueryParameters build() {
    return const DesignerQueryParameters(
      page: 1,
      pageSize: 10,
      sort: 'newest',
    );
  }

  void setParams(DesignerQueryParameters params) {
    state = params;
  }

  void setStyle(String style) {
    state = state.copyWith(style: style, page: 1);
  }

  void clearStyle() {
    state = state.copyWith(clearStyle: true, page: 1);
  }

  void resetFilters() {
    state = const DesignerQueryParameters(
      page: 1,
      pageSize: 10,
      sort: 'newest',
    );
  }
}

final designerFilterProvider =
    NotifierProvider<DesignerFilterNotifier, DesignerQueryParameters>(
  DesignerFilterNotifier.new,
);
