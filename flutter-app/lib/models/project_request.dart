import 'style_analysis_result.dart';

class ProjectRequestPhotoModel {
  final String id;
  final String photoUrl;
  final String imageType; // "RoomPhoto" or "Moodboard"
  final String storageKey;
  final DateTime uploadedAt;

  ProjectRequestPhotoModel({
    required this.id,
    required this.photoUrl,
    required this.imageType,
    required this.storageKey,
    required this.uploadedAt,
  });

  factory ProjectRequestPhotoModel.fromJson(Map<String, dynamic> json) {
    return ProjectRequestPhotoModel(
      id: json['id']?.toString() ?? '',
      photoUrl: json['imageUrl'] ?? json['photoUrl'] ?? '',
      imageType: json['imageType'] ?? 'Moodboard',
      storageKey: json['storageKey'] ?? '',
      uploadedAt: DateTime.tryParse(json['createdAtUtc'] ?? json['uploadedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ColorPaletteChip {
  final String hexCode;
  final String colorName;

  ColorPaletteChip({required this.hexCode, required this.colorName});

  factory ColorPaletteChip.fromJson(Map<String, dynamic> json) {
    return ColorPaletteChip(
      hexCode: json['hexCode'] ?? '#FFFFFF',
      colorName: json['colorName'] ?? 'Color',
    );
  }
}

class StatusHistoryItem {
  final String status;
  final String? reason;
  final String? changedBy;
  final DateTime createdAt;

  StatusHistoryItem({
    required this.status,
    this.reason,
    this.changedBy,
    required this.createdAt,
  });

  factory StatusHistoryItem.fromJson(Map<String, dynamic> json) {
    return StatusHistoryItem(
      status: json['status'] ?? '',
      reason: json['reason'],
      changedBy: json['changedBy'],
      createdAt: DateTime.tryParse(json['createdAtUtc'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ProjectRequestModel {
  final String id;
  final String clientId;
  final String clientName;
  final String title;
  final String roomType;
  final double roomSize;
  final double lengthFeet;
  final double widthFeet;
  final double heightFeet;
  final double budgetLkr;
  final double? budgetMin;
  final double? budgetMax;
  final List<String> preferredStyles;
  final List<String> preferredColours;
  final String description;
  final String status;
  final String? rejectionReason;
  final String? flagReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProjectRequestPhotoModel> photos;
  final List<ColorPaletteChip> suggestedPalette;
  final List<StatusHistoryItem> statusHistory;
  final StyleAnalysisResultModel? styleAnalysis;

  ProjectRequestModel({
    required this.id,
    required this.clientId,
    this.clientName = 'Client',
    required this.title,
    required this.roomType,
    required this.roomSize,
    required this.lengthFeet,
    required this.widthFeet,
    required this.heightFeet,
    required this.budgetLkr,
    this.budgetMin,
    this.budgetMax,
    required this.preferredStyles,
    required this.preferredColours,
    required this.description,
    required this.status,
    this.rejectionReason,
    this.flagReason,
    required this.createdAt,
    required this.updatedAt,
    required this.photos,
    required this.suggestedPalette,
    required this.statusHistory,
    this.styleAnalysis,
  });

  factory ProjectRequestModel.fromJson(Map<String, dynamic> json) {
    final double budget = (json['budgetMin'] as num?)?.toDouble() ??
        (json['budgetMax'] as num?)?.toDouble() ??
        (json['budgetLkr'] as num?)?.toDouble() ??
        0.0;

    final double size = (json['roomSize'] as num?)?.toDouble() ?? 150.0;

    List<String> colors = [];
    if (json['preferredColours'] is String && (json['preferredColours'] as String).isNotEmpty) {
      colors = (json['preferredColours'] as String).split(',').map((c) => c.trim()).toList();
    } else if (json['preferredColours'] is List) {
      colors = List<String>.from(json['preferredColours']);
    }

    List<String> styles = [];
    if (json['stylePreferences'] is String && (json['stylePreferences'] as String).isNotEmpty) {
      styles = (json['stylePreferences'] as String).split(',').map((s) => s.trim()).toList();
    } else if (json['preferredStyles'] is List) {
      styles = List<String>.from(json['preferredStyles']);
    }

    return ProjectRequestModel(
      id: json['id']?.toString() ?? '',
      clientId: json['clientId']?.toString() ?? '',
      clientName: json['clientName'] ?? 'Client',
      title: json['title'] ?? '${json['roomType'] ?? 'Room'} Makeover',
      roomType: json['roomType'] ?? 'LivingRoom',
      roomSize: size,
      lengthFeet: (json['lengthFeet'] as num?)?.toDouble() ?? 15.0,
      widthFeet: (json['widthFeet'] as num?)?.toDouble() ?? 10.0,
      heightFeet: (json['heightFeet'] as num?)?.toDouble() ?? 9.0,
      budgetLkr: budget,
      budgetMin: (json['budgetMin'] as num?)?.toDouble(),
      budgetMax: (json['budgetMax'] as num?)?.toDouble(),
      preferredStyles: styles,
      preferredColours: colors,
      description: json['description'] ?? '',
      status: json['status'] ?? 'Draft',
      rejectionReason: json['rejectionReason'],
      flagReason: json['flagReason'],
      createdAt: DateTime.tryParse(json['createdAtUtc'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAtUtc'] ?? json['updatedAt'] ?? '') ?? DateTime.now(),
      photos: (json['images'] as List<dynamic>?)
              ?.map((p) => ProjectRequestPhotoModel.fromJson(p))
              .toList() ??
          (json['photos'] as List<dynamic>?)
              ?.map((p) => ProjectRequestPhotoModel.fromJson(p))
              .toList() ??
          [],
      suggestedPalette: (json['suggestedPalettes'] as List<dynamic>?)
              ?.map((p) => ColorPaletteChip.fromJson(p))
              .toList() ??
          [
            ColorPaletteChip(hexCode: '#F4F1EA', colorName: 'Warm White'),
            ColorPaletteChip(hexCode: '#C2A68C', colorName: 'Oatmeal'),
            ColorPaletteChip(hexCode: '#2C3E50', colorName: 'Midnight Navy'),
            ColorPaletteChip(hexCode: '#8C9A86', colorName: 'Sage Green'),
          ],
      statusHistory: (json['statusHistory'] as List<dynamic>?)
              ?.map((h) => StatusHistoryItem.fromJson(h))
              .toList() ??
          [],
      styleAnalysis: json['styleAnalysis'] != null
          ? StyleAnalysisResultModel.fromJson(json['styleAnalysis'])
          : null,
    );
  }
}
