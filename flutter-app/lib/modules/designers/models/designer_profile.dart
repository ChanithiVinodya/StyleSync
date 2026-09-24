import 'designer_summary.dart';
import 'portfolio_item.dart';

class DesignerProfile {
  final int id;
  final int userId;
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
  final DateTime createdAtUtc;
  final List<PortfolioItem> portfolioItems;

  const DesignerProfile({
    required this.id,
    required this.userId,
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
    required this.createdAtUtc,
    required this.portfolioItems,
  });

  factory DesignerProfile.fromJson(Map<String, dynamic> json) {
    final rawItems = json['portfolioItems'] as List<dynamic>? ?? [];
    return DesignerProfile(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num?)?.toInt() ?? 0,
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
      createdAtUtc: json['createdAtUtc'] != null
          ? DateTime.tryParse(json['createdAtUtc'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      portfolioItems:
          rawItems.map((e) => PortfolioItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
