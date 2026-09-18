class StyleAnalysisResultModel {
  final String id;
  final String primaryStyle;
  final String secondaryStyle;
  final double confidenceScore;
  final List<String> recommendedColors;
  final List<String> detectedFeatures;
  final String analysisSummary;
  final String conceptRenderUrl;
  final DateTime analyzedAt;

  StyleAnalysisResultModel({
    required this.id,
    required this.primaryStyle,
    required this.secondaryStyle,
    required this.confidenceScore,
    required this.recommendedColors,
    required this.detectedFeatures,
    required this.analysisSummary,
    required this.conceptRenderUrl,
    required this.analyzedAt,
  });

  factory StyleAnalysisResultModel.fromJson(Map<String, dynamic> json) {
    return StyleAnalysisResultModel(
      id: json['id'] ?? '',
      primaryStyle: json['primaryStyle'] ?? 'Modern',
      secondaryStyle: json['secondaryStyle'] ?? 'Minimalist',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 85.0,
      recommendedColors: List<String>.from(json['recommendedColors'] ?? []),
      detectedFeatures: List<String>.from(json['detectedFeatures'] ?? []),
      analysisSummary: json['analysisSummary'] ?? '',
      conceptRenderUrl: json['conceptRenderUrl'] ?? '',
      analyzedAt: DateTime.tryParse(json['analyzedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
