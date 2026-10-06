import 'quote_item.dart';

class QuoteVersionItem {
  final String id;
  final String description;
  final String category;
  final int quantity;
  final double unitCost;
  final double lineTotal;

  QuoteVersionItem({
    required this.id,
    required this.description,
    required this.category,
    required this.quantity,
    required this.unitCost,
    required this.lineTotal,
  });

  factory QuoteVersionItem.fromJson(Map<String, dynamic> json) {
    return QuoteVersionItem(
      id: json['id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Other',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class QuoteVersion {
  final String id;
  final int versionNumber;
  final String authorId;
  final String authorRole;
  final double materialsSubtotal;
  final double laborSubtotal;
  final double designFee;
  final double contingencyAmount;
  final double taxAmount;
  final double totalCost;
  final String? notes;
  final DateTime createdAt;
  final List<QuoteVersionItem> items;

  QuoteVersion({
    required this.id,
    required this.versionNumber,
    required this.authorId,
    required this.authorRole,
    required this.materialsSubtotal,
    required this.laborSubtotal,
    required this.designFee,
    required this.contingencyAmount,
    required this.taxAmount,
    required this.totalCost,
    this.notes,
    required this.createdAt,
    this.items = const [],
  });

  factory QuoteVersion.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return QuoteVersion(
      id: json['id']?.toString() ?? '',
      versionNumber: (json['versionNumber'] as num?)?.toInt() ?? 1,
      authorId: json['authorId']?.toString() ?? '',
      authorRole: json['authorRole']?.toString() ?? 'Designer',
      materialsSubtotal: (json['materialsSubtotal'] as num?)?.toDouble() ?? 0.0,
      laborSubtotal: (json['laborSubtotal'] as num?)?.toDouble() ?? 0.0,
      designFee: (json['designFee'] as num?)?.toDouble() ?? 0.0,
      contingencyAmount: (json['contingencyAmount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      items: rawItems.map((e) => QuoteVersionItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class DesignerRecommendation {
  final String userId;
  final int profileId;
  final String displayName;
  final String? email;
  final double matchScore;
  final double styleTagOverlapPct;
  final double budgetRangeOverlapPct;
  final double pastRatingNormalized;
  final double availabilityBonus;
  final double? averageRating;
  final List<String> styleTags;
  final double priceRangeMin;
  final double priceRangeMax;
  final String? featuredImageUrl;
  final String? bio;
  final String? matchReason;

  String get designerId => userId;
  double get rating => averageRating ?? 5.0;
  int get reviewCount => 12;
  double get hourlyRate => priceRangeMin > 0 ? priceRangeMin : 75.0;
  int get experienceYears => 5;
  List<String> get specializations => styleTags;
  Map<String, String> get factorExplanations => {
    'Style Compatibility (40%)': '${(styleTagOverlapPct * 100).toStringAsFixed(0)}% style tag alignment',
    'Budget Range Overlap (30%)': '${(budgetRangeOverlapPct * 100).toStringAsFixed(0)}% budget range fit',
    'Past Rating (20%)': '${(pastRatingNormalized * 5.0).toStringAsFixed(1)} / 5.0 client feedback score',
    'Availability (10%)': availabilityBonus > 0 ? 'Verified available capacity' : 'Standard project workload',
  };

  DesignerRecommendation({
    required this.userId,
    required this.profileId,
    required this.displayName,
    this.email,
    required this.matchScore,
    this.styleTagOverlapPct = 0.0,
    this.budgetRangeOverlapPct = 0.0,
    this.pastRatingNormalized = 0.0,
    this.availabilityBonus = 0.0,
    this.averageRating,
    this.styleTags = const [],
    this.priceRangeMin = 0.0,
    this.priceRangeMax = 0.0,
    this.featuredImageUrl,
    this.bio,
    this.matchReason,
  });

  factory DesignerRecommendation.fromJson(Map<String, dynamic> json) {
    return DesignerRecommendation(
      userId: json['userId']?.toString() ?? '',
      profileId: (json['profileId'] as num?)?.toInt() ?? 0,
      displayName: json['displayName']?.toString() ?? '',
      email: json['email']?.toString(),
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0.0,
      styleTagOverlapPct: (json['styleTagOverlapPct'] as num?)?.toDouble() ?? 0.0,
      budgetRangeOverlapPct: (json['budgetRangeOverlapPct'] as num?)?.toDouble() ?? 0.0,
      pastRatingNormalized: (json['pastRatingNormalized'] as num?)?.toDouble() ?? 0.0,
      availabilityBonus: (json['availabilityBonus'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      styleTags: (json['styleTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      priceRangeMin: (json['priceRangeMin'] as num?)?.toDouble() ?? 0.0,
      priceRangeMax: (json['priceRangeMax'] as num?)?.toDouble() ?? 0.0,
      featuredImageUrl: json['featuredImageUrl']?.toString(),
      bio: json['bio']?.toString(),
      matchReason: json['matchReason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'profileId': profileId,
      'displayName': displayName,
      if (email != null) 'email': email,
      'matchScore': matchScore,
      'styleTagOverlapPct': styleTagOverlapPct,
      'budgetRangeOverlapPct': budgetRangeOverlapPct,
      'pastRatingNormalized': pastRatingNormalized,
      'availabilityBonus': availabilityBonus,
      if (averageRating != null) 'averageRating': averageRating,
      'styleTags': styleTags,
      'priceRangeMin': priceRangeMin,
      'priceRangeMax': priceRangeMax,
      if (featuredImageUrl != null) 'featuredImageUrl': featuredImageUrl,
      if (bio != null) 'bio': bio,
      if (matchReason != null) 'matchReason': matchReason,
    };
  }
}

class Quote {
  final String id;
  final String projectRequestId;
  final String designerId;
  final String scopeSummary;
  final String? notes;
  final bool isAiGenerated;
  final String status;
  final double totalCost;
  final List<QuoteItem> items;
  final QuoteVersion? currentVersion;
  final List<QuoteVersion> versions;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? contractId;
  final String? designerDisplayName;
  final String? designerEmail;
  final String? clientDisplayName;
  final String? clientEmail;
  final String? projectReferenceCode;
  final String? description;
  final List<DesignerRecommendation> recommendedDesigners;

  Quote({
    required this.id,
    required this.projectRequestId,
    required this.designerId,
    required this.scopeSummary,
    this.notes,
    this.isAiGenerated = false,
    this.status = 'Draft',
    required this.totalCost,
    this.items = const [],
    this.currentVersion,
    this.versions = const [],
    this.createdAt,
    this.updatedAt,
    this.contractId,
    this.designerDisplayName,
    this.designerEmail,
    this.clientDisplayName,
    this.clientEmail,
    this.projectReferenceCode,
    this.description,
    this.recommendedDesigners = const [],
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    String statusStr = 'Draft';
    if (json['status'] != null) {
      if (json['status'] is String) {
        statusStr = json['status'];
      } else if (json['status'] is Map) {
        statusStr = json['status']['name'] ?? json['status']['value'] ?? 'Draft';
      } else {
        statusStr = json['status'].toString();
      }
    }

    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = <QuoteItem>[];
    for (final item in rawItems) {
      if (item is Map) {
        try {
          itemsList.add(QuoteItem.fromJson(Map<String, dynamic>.from(item)));
        } catch (e) {
          // ignore item parse error
        }
      }
    }

    QuoteVersion? currentVer;
    if (json['currentVersion'] != null && json['currentVersion'] is Map<String, dynamic>) {
      currentVer = QuoteVersion.fromJson(json['currentVersion']);
    }

    final rawVersions = json['versions'] as List<dynamic>? ?? [];
    final versionsList = rawVersions.map((e) => QuoteVersion.fromJson(e as Map<String, dynamic>)).toList();

    double total = (json['totalCost'] is num)
        ? (json['totalCost'] as num).toDouble()
        : double.tryParse(json['totalCost']?.toString() ?? '0') ?? 0.0;

    if (total == 0 && itemsList.isNotEmpty) {
      total = itemsList.fold(0.0, (sum, i) => sum + i.calculatedTotal);
    }

    DateTime? created;
    if (json['createdAt'] != null) {
      created = DateTime.tryParse(json['createdAt'].toString());
    }
    DateTime? updated;
    if (json['updatedAt'] != null) {
      updated = DateTime.tryParse(json['updatedAt'].toString());
    }

    final rawRecs = json['recommendedDesigners'] as List<dynamic>? ?? [];
    final recsList = <DesignerRecommendation>[];
    for (final r in rawRecs) {
      if (r is Map) {
        try {
          recsList.add(DesignerRecommendation.fromJson(Map<String, dynamic>.from(r)));
        } catch (_) {}
      }
    }

    return Quote(
      id: json['id']?.toString() ?? '',
      projectRequestId: json['projectRequestId']?.toString() ?? '',
      designerId: json['designerId']?.toString() ?? '',
      scopeSummary: json['scopeSummary']?.toString() ?? 'Untitled Scope',
      notes: json['notes']?.toString(),
      isAiGenerated: json['isAiGenerated'] == true,
      status: statusStr,
      totalCost: total,
      items: itemsList,
      currentVersion: currentVer,
      versions: versionsList,
      createdAt: created,
      updatedAt: updated,
      contractId: json['contractId']?.toString(),
      designerDisplayName: json['designerDisplayName']?.toString(),
      designerEmail: json['designerEmail']?.toString(),
      clientDisplayName: json['clientDisplayName']?.toString(),
      clientEmail: json['clientEmail']?.toString(),
      projectReferenceCode: json['projectReferenceCode']?.toString(),
      description: json['description']?.toString(),
      recommendedDesigners: recsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectRequestId': projectRequestId,
      'designerId': designerId,
      'scopeSummary': scopeSummary,
      if (notes != null) 'notes': notes,
      'isAiGenerated': isAiGenerated,
      'status': status,
      'totalCost': totalCost,
      'items': items.map((e) => e.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (contractId != null) 'contractId': contractId,
      if (designerDisplayName != null) 'designerDisplayName': designerDisplayName,
      if (designerEmail != null) 'designerEmail': designerEmail,
      if (clientDisplayName != null) 'clientDisplayName': clientDisplayName,
      if (clientEmail != null) 'clientEmail': clientEmail,
      if (projectReferenceCode != null) 'projectReferenceCode': projectReferenceCode,
      if (description != null) 'description': description,
      if (recommendedDesigners.isNotEmpty)
        'recommendedDesigners': recommendedDesigners.map((e) => e.toJson()).toList(),
    };
  }

  Quote copyWith({
    String? id,
    String? projectRequestId,
    String? designerId,
    String? scopeSummary,
    String? notes,
    bool? isAiGenerated,
    String? status,
    double? totalCost,
    List<QuoteItem>? items,
    QuoteVersion? currentVersion,
    List<QuoteVersion>? versions,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? contractId,
    String? designerDisplayName,
    String? designerEmail,
    String? clientDisplayName,
    String? clientEmail,
    String? projectReferenceCode,
    String? description,
    List<DesignerRecommendation>? recommendedDesigners,
  }) {
    return Quote(
      id: id ?? this.id,
      projectRequestId: projectRequestId ?? this.projectRequestId,
      designerId: designerId ?? this.designerId,
      scopeSummary: scopeSummary ?? this.scopeSummary,
      notes: notes ?? this.notes,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      status: status ?? this.status,
      totalCost: totalCost ?? this.totalCost,
      items: items ?? this.items,
      currentVersion: currentVersion ?? this.currentVersion,
      versions: versions ?? this.versions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contractId: contractId ?? this.contractId,
      designerDisplayName: designerDisplayName ?? this.designerDisplayName,
      designerEmail: designerEmail ?? this.designerEmail,
      clientDisplayName: clientDisplayName ?? this.clientDisplayName,
      clientEmail: clientEmail ?? this.clientEmail,
      projectReferenceCode: projectReferenceCode ?? this.projectReferenceCode,
      description: description ?? this.description,
      recommendedDesigners: recommendedDesigners ?? this.recommendedDesigners,
    );
  }
}
