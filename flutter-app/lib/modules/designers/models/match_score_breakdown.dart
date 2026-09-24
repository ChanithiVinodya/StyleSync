class MatchScoreBreakdownResponse {
  final int designerId;
  final double styleTagOverlapPct;
  final double budgetRangeOverlapPct;
  final double pastRatingNormalized;
  final double availabilityBonus;
  final double matchScore;
  final double? averageRating;

  const MatchScoreBreakdownResponse({
    required this.designerId,
    required this.styleTagOverlapPct,
    required this.budgetRangeOverlapPct,
    required this.pastRatingNormalized,
    required this.availabilityBonus,
    required this.matchScore,
    this.averageRating,
  });

  factory MatchScoreBreakdownResponse.fromJson(Map<String, dynamic> json) {
    return MatchScoreBreakdownResponse(
      designerId: (json['designerId'] as num?)?.toInt() ?? 0,
      styleTagOverlapPct:
          (json['styleTagOverlapPct'] as num?)?.toDouble() ?? 0.0,
      budgetRangeOverlapPct:
          (json['budgetRangeOverlapPct'] as num?)?.toDouble() ?? 0.0,
      pastRatingNormalized:
          (json['pastRatingNormalized'] as num?)?.toDouble() ?? 0.5,
      availabilityBonus:
          (json['availabilityBonus'] as num?)?.toDouble() ?? 0.0,
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
    );
  }
}
