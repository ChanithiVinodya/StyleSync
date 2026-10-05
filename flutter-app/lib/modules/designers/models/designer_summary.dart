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
      id: (json['id'] as num).toInt(),
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
      priceRangeMin: (json['priceRangeMin'] as num?)?.toDouble() ?? 0.0,
      priceRangeMax: (json['priceRangeMax'] as num?)?.toDouble() ?? 0.0,
      ratePerSqFt: (json['ratePerSqFt'] as num?)?.toDouble() ?? 0.0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      maxConcurrentProjects:
          (json['maxConcurrentProjects'] as num?)?.toInt() ?? 3,
      activeProjectCount:
          (json['activeProjectCount'] as num?)?.toInt() ?? 0,
      remainingCapacity:
          (json['remainingCapacity'] as num?)?.toInt() ?? 3,
      isUnderCapacity: json['isUnderCapacity'] as bool? ?? true,
      isAtCapacity: json['isAtCapacity'] as bool? ?? false,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      listingStatus: ListingStatus.fromValue(
          (json['listingStatus'] as num?)?.toInt() ?? 1),
      publishedPortfolioCount:
          (json['publishedPortfolioCount'] as num?)?.toInt() ?? 0,
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
  final double? budgetMin;
  final double? budgetMax;
  final bool? available;
  final String? sort;
  final int page;
  final int pageSize;

  const DesignerQueryParameters({
    this.style,
    this.budgetMin,
    this.budgetMax,
    this.available,
    this.sort = 'newest',
    this.page = 1,
    this.pageSize = 10,
  });

  DesignerQueryParameters copyWith({
    String? style,
    double? budgetMin,
    double? budgetMax,
    bool? available,
    String? sort,
    int? page,
    int? pageSize,
    bool clearStyle = false,
    bool clearBudget = false,
    bool clearAvailable = false,
  }) {
    return DesignerQueryParameters(
      style: clearStyle ? null : (style ?? this.style),
      budgetMin: clearBudget ? null : (budgetMin ?? this.budgetMin),
      budgetMax: clearBudget ? null : (budgetMax ?? this.budgetMax),
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
    if (budgetMin != null && budgetMin! > 0) {
      params['budgetMin'] = budgetMin!.toInt().toString();
    }
    if (budgetMax != null && budgetMax! > 0) {
      params['budgetMax'] = budgetMax!.toInt().toString();
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
