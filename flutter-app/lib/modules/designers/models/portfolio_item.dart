import 'designer_summary.dart';

class PortfolioItem {
  final int id;
  final int designerProfileId;
  final String title;
  final String description;
  final String imageUrl;
  final String budgetRangeLabel;
  final String clientInitials;
  final ListingStatus completionStatusBadge;
  final DateTime createdAtUtc;

  const PortfolioItem({
    required this.id,
    required this.designerProfileId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.budgetRangeLabel,
    required this.clientInitials,
    required this.completionStatusBadge,
    required this.createdAtUtc,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: (json['id'] as num?)?.toInt() ?? int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      designerProfileId: (json['designerProfileId'] as num?)?.toInt() ?? int.tryParse(json['designerProfileId']?.toString() ?? '0') ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      budgetRangeLabel: json['budgetRangeLabel'] as String? ?? '',
      clientInitials: json['clientInitials'] as String? ?? '',
      completionStatusBadge: ListingStatus.fromJson(json['completionStatusBadge']),
      createdAtUtc: json['createdAtUtc'] != null
          ? DateTime.tryParse(json['createdAtUtc'].toString()) ??
              DateTime.now()
          : DateTime.now(),
    );
  }
}
