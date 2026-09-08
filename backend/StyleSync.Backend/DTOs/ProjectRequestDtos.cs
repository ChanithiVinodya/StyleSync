using StyleSync.Backend.Domain.Enums;

namespace StyleSync.Backend.DTOs;

public record CreateProjectRequestDto(
    string RoomType,
    double LengthFeet,
    double WidthFeet,
    double HeightFeet,
    decimal BudgetLkr,
    List<string> PreferredStyles,
    string Description,
    bool SubmitImmediately = false,
    List<string>? PhotoUrls = null
);

public record UpdateProjectRequestDto(
    string RoomType,
    double LengthFeet,
    double WidthFeet,
    double HeightFeet,
    decimal BudgetLkr,
    List<string> PreferredStyles,
    string Description
);

public record ProjectRequestPhotoDto(
    Guid Id,
    string PhotoUrl,
    string StorageKey,
    DateTime UploadedAt
);

public record StyleAnalysisResultDto(
    Guid Id,
    string PrimaryStyle,
    string SecondaryStyle,
    double ConfidenceScore,
    List<string> RecommendedColors,
    List<string> DetectedFeatures,
    string AnalysisSummary,
    string ConceptRenderUrl,
    DateTime AnalyzedAt
);

public record ProjectRequestResponseDto(
    Guid Id,
    string ClientId,
    string RoomType,
    double LengthFeet,
    double WidthFeet,
    double HeightFeet,
    decimal BudgetLkr,
    List<string> PreferredStyles,
    string Description,
    string Status,
    DateTime CreatedAt,
    DateTime UpdatedAt,
    List<ProjectRequestPhotoDto> Photos,
    StyleAnalysisResultDto? StyleAnalysis
);

public record AIStyleAnalysisRequestDto(
    Guid ProjectRequestId,
    string RoomType,
    List<string> PreferredStyles,
    string Description,
    List<string> PhotoUrls
);

public record AIStyleAnalysisResponseDto(
    string PrimaryStyle,
    string SecondaryStyle,
    double ConfidenceScore,
    List<string> RecommendedColors,
    List<string> DetectedFeatures,
    string AnalysisSummary,
    string ConceptRenderUrl = ""
);
