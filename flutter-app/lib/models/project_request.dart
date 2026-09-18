import 'style_analysis_result.dart';

class ProjectRequestPhotoModel {
  final String id;
  final String photoUrl;
  final String storageKey;
  final DateTime uploadedAt;

  ProjectRequestPhotoModel({
    required this.id,
    required this.photoUrl,
    required this.storageKey,
    required this.uploadedAt,
  });

  factory ProjectRequestPhotoModel.fromJson(Map<String, dynamic> json) {
    return ProjectRequestPhotoModel(
      id: json['id'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      storageKey: json['storageKey'] ?? '',
      uploadedAt: DateTime.tryParse(json['uploadedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ProjectRequestModel {
  final String id;
  final String clientId;
  final String roomType;
  final double lengthFeet;
  final double widthFeet;
  final double heightFeet;
  final double budgetLkr;
  final List<String> preferredStyles;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProjectRequestPhotoModel> photos;
  final StyleAnalysisResultModel? styleAnalysis;

  ProjectRequestModel({
    required this.id,
    required this.clientId,
    required this.roomType,
    required this.lengthFeet,
    required this.widthFeet,
    required this.heightFeet,
    required this.budgetLkr,
    required this.preferredStyles,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.photos,
    this.styleAnalysis,
  });

  factory ProjectRequestModel.fromJson(Map<String, dynamic> json) {
    return ProjectRequestModel(
      id: json['id'] ?? '',
      clientId: json['clientId'] ?? '',
      roomType: json['roomType'] ?? '',
      lengthFeet: (json['lengthFeet'] as num?)?.toDouble() ?? 0.0,
      widthFeet: (json['widthFeet'] as num?)?.toDouble() ?? 0.0,
      heightFeet: (json['heightFeet'] as num?)?.toDouble() ?? 0.0,
      budgetLkr: (json['budgetLkr'] as num?)?.toDouble() ?? 0.0,
      preferredStyles: List<String>.from(json['preferredStyles'] ?? []),
      description: json['description'] ?? '',
      status: json['status'] ?? 'Draft',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      photos: (json['photos'] as List<dynamic>?)
              ?.map((p) => ProjectRequestPhotoModel.fromJson(p))
              .toList() ??
          [],
      styleAnalysis: json['styleAnalysis'] != null
          ? StyleAnalysisResultModel.fromJson(json['styleAnalysis'])
          : null,
    );
  }
}
