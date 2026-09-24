class PagedResult<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PagedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => fromJsonT(e as Map<String, dynamic>))
        .toList();

    final page = (json['page'] as num?)?.toInt() ?? 1;
    final pageSize = (json['pageSize'] as num?)?.toInt() ?? 10;
    final totalCount = (json['totalCount'] as num?)?.toInt() ?? items.length;
    final totalPages = (json['totalPages'] as num?)?.toInt() ?? 
        ((totalCount / (pageSize > 0 ? pageSize : 10)).ceil());

    return PagedResult<T>(
      items: items,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
      totalPages: totalPages,
      hasNextPage: json['hasNextPage'] as bool? ?? (page < totalPages),
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? (page > 1),
    );
  }
}
