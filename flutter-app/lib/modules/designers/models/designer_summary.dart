enum ListingStatus {
  draft(0),
  published(1),
  suspended(2),
  archived(3);

  final int value;
  const ListingStatus(this.value);

  static ListingStatus fromValue(int val) {
    return ListingStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => ListingStatus.draft,
    );
  }

  static ListingStatus fromJson(dynamic val) {
    if (val == null) return ListingStatus.published;
    if (val is int) return fromValue(val);
    if (val is num) return fromValue(val.toInt());
    if (val is String) {
      final str = val.trim().toLowerCase();
      return ListingStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == str,
        orElse: () {
          final parsed = int.tryParse(str);
          if (parsed != null) return fromValue(parsed);
          return ListingStatus.published;
        },
      );
    }
    return ListingStatus.published;
  }
}

class DesignerSummary {
  final int id;
  final String displayName;
  final String bio;
  final List<String> styleTags;
  final List<String> serviceCategories;
  final double priceRangeMin;
  final double priceRangeMax;
  final double ratePerSqFt;
  final bool isAvailable;
  final int maxConcurrentProjects;
  final int activeProjectCount;
  final int remainingCapacity;
  final bool isUnderCapacity;
  final bool isAtCapacity;
  final double? averageRating;
  final ListingStatus listingStatus;
  final int publishedPortfolioCount;
  final String? featuredImageUrl;
  final DateTime createdAtUtc;

  const DesignerSummary({
    required this.id,
    required this.displayName,
    required this.bio,
    required this.styleTags,
    required this.serviceCategories,
    required this.priceRangeMin,
    required this.priceRangeMax,
    required this.ratePerSqFt,
    required this.isAvailable,
    required this.maxConcurrentProjects,
    required this.activeProjectCount,
    required this.remainingCapacity,
    required this.isUnderCapacity,
    required this.isAtCapacity,
    this.averageRating,
    required this.listingStatus,
    required this.publishedPortfolioCount,
    this.featuredImageUrl,
    required this.createdAtUtc,
  });

  factory DesignerSummary.fromJson(Map<String, dynamic> json) {
    return DesignerSummary(
      id: (json['id'] as num?)?.toInt() ?? int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      displayName: json['displayName'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      styleTags: (json['styleTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      serviceCategories: (json['serviceCategories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      priceRangeMin: (json['priceRangeMin'] as num?)?.toDouble() ?? double.tryParse(json['priceRangeMin']?.toString() ?? '0') ?? 0.0,
      priceRangeMax: (json['priceRangeMax'] as num?)?.toDouble() ?? double.tryParse(json['priceRangeMax']?.toString() ?? '0') ?? 0.0,
      ratePerSqFt: (json['ratePerSqFt'] as num?)?.toDouble() ?? double.tryParse(json['ratePerSqFt']?.toString() ?? '0') ?? 0.0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      maxConcurrentProjects:
          (json['maxConcurrentProjects'] as num?)?.toInt() ?? 3,
      activeProjectCount:
          (json['activeProjectCount'] as num?)?.toInt() ?? 0,
      remainingCapacity:
          (json['remainingCapacity'] as num?)?.toInt() ?? 3,
      isUnderCapacity: json['isUnderCapacity'] as bool? ?? true,
      isAtCapacity: json['isAtCapacity'] as bool? ?? false,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? (json['averageRating'] != null ? double.tryParse(json['averageRating'].toString()) : null),
      listingStatus: ListingStatus.fromJson(json['listingStatus']),
      publishedPortfolioCount:
          (json['publishedPortfolioCount'] as num?)?.toInt() ?? int.tryParse(json['publishedPortfolioCount']?.toString() ?? '0') ?? 0,
      featuredImageUrl: json['featuredImageUrl'] as String?,
      createdAtUtc: json['createdAtUtc'] != null
          ? DateTime.tryParse(json['createdAtUtc'].toString()) ??
              DateTime.now()
          : DateTime.now(),
    );
  }
}

class DesignerQueryParameters {
  final String? style;
  final String? search;
  final double? budgetMin;
  final double? budgetMax;
  final bool? available;
  final String? sort;
  final int page;
  final int pageSize;

  const DesignerQueryParameters({
    this.style,
    this.search,
    this.budgetMin,
    this.budgetMax,
    this.available,
    this.sort = 'newest',
    this.page = 1,
    this.pageSize = 10,
  });

  DesignerQueryParameters copyWith({
    String? style,
    String? search,
    double? budgetMin,
    double? budgetMax,
    bool? available,
    String? sort,
    int? page,
    int? pageSize,
    bool clearStyle = false,
    bool clearSearch = false,
    bool clearBudget = false,
    bool clearBudgetMin = false,
    bool clearBudgetMax = false,
    bool clearAvailable = false,
  }) {
    return DesignerQueryParameters(
      style: clearStyle ? null : (style ?? this.style),
      search: clearSearch ? null : (search ?? this.search),
      budgetMin: (clearBudget || clearBudgetMin) ? null : (budgetMin ?? this.budgetMin),
      budgetMax: (clearBudget || clearBudgetMax) ? null : (budgetMax ?? this.budgetMax),
      available: clearAvailable ? null : (available ?? this.available),
      sort: sort ?? this.sort,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    if (style != null && style!.isNotEmpty && style != 'All') {
      params['style'] = style!;
    }
    if (search != null && search!.trim().isNotEmpty) {
      params['search'] = search!.trim();
    }
    var minVal = budgetMin != null && budgetMin! > 0 ? budgetMin : null;
    var maxVal = budgetMax != null && budgetMax! > 0 ? budgetMax : null;
    if (minVal != null && maxVal != null && minVal > maxVal) {
      final temp = minVal;
      minVal = maxVal;
      maxVal = temp;
    }
    if (minVal != null) {
      params['budgetMin'] = minVal.toInt().toString();
    }
    if (maxVal != null) {
      params['budgetMax'] = maxVal.toInt().toString();
    }
    if (available != null) {
      params['available'] = available!.toString();
    }
    if (sort != null && sort!.isNotEmpty) {
      params['sort'] = sort!;
    }
    params['page'] = page.toString();
    params['pageSize'] = pageSize.toString();
    return params;
  }
}
