using System.ComponentModel.DataAnnotations;
using StyleSync.Api.Modules.ProjectRequests.Models;

namespace StyleSync.Api.Modules.ProjectRequests.DTOs;

// ─── Request DTOs ─────────────────────────────────────────────────────────────

public class CreateProjectRequestDto
{
    [Required(ErrorMessage = "Title is required.")]
    [StringLength(150, MinimumLength = 3, ErrorMessage = "Title must be between 3 and 150 characters.")]
    public string Title { get; set; } = string.Empty;

    [Required(ErrorMessage = "Description is required.")]
    [StringLength(2000, MinimumLength = 10, ErrorMessage = "Description must be between 10 and 2000 characters.")]
    public string Description { get; set; } = string.Empty;

    [Required(ErrorMessage = "Room type is required.")]
    public RoomType RoomType { get; set; }

    [Range(0.1, 100000, ErrorMessage = "Room size must be positive (> 0 sq ft).")]
    public decimal? RoomSize { get; set; }

    [Range(0.01, 100_000_000, ErrorMessage = "Budget minimum must be a positive value (> 0).")]
    public decimal? BudgetMin { get; set; }

    [Range(0.01, 100_000_000, ErrorMessage = "Budget maximum must be a positive value (> 0).")]
    public decimal? BudgetMax { get; set; }

    public DateTime? PreferredStartDate { get; set; }
    public DateTime? PreferredEndDate { get; set; }

    [StringLength(500, ErrorMessage = "Style preferences cannot exceed 500 characters.")]
    public string? StylePreferences { get; set; }

    [StringLength(500, ErrorMessage = "Preferred colours cannot exceed 500 characters.")]
    public string? PreferredColours { get; set; }

    [StringLength(1000, ErrorMessage = "Special requirements cannot exceed 1000 characters.")]
    public string? SpecialRequirements { get; set; }

    public List<UploadImageDto>? Images { get; set; }

    /// <summary>If true, immediately runs validation and submits for AI workflow.</summary>
    public bool SubmitImmediately { get; set; } = false;
}

public class UpdateProjectRequestDto
{
    [StringLength(150, MinimumLength = 3)]
    public string? Title { get; set; }

    [StringLength(2000, MinimumLength = 10)]
    public string? Description { get; set; }

    public RoomType? RoomType { get; set; }

    [Range(0.1, 100000)]
    public decimal? RoomSize { get; set; }

    [Range(0.01, 100_000_000)]
    public decimal? BudgetMin { get; set; }

    [Range(0.01, 100_000_000)]
    public decimal? BudgetMax { get; set; }

    public DateTime? PreferredStartDate { get; set; }
    public DateTime? PreferredEndDate { get; set; }

    [StringLength(500)]
    public string? StylePreferences { get; set; }

    [StringLength(500)]
    public string? PreferredColours { get; set; }

    [StringLength(1000)]
    public string? SpecialRequirements { get; set; }
}

public class UploadImageDto
{
    [Required]
    public string ImageUrl { get; set; } = string.Empty;

    public string ImageType { get; set; } = "Moodboard"; // "RoomPhoto" or "Moodboard"

    public string? StorageKey { get; set; }
}

public class FlagProjectRequestDto
{
    [Required(ErrorMessage = "A reason is required when flagging/cancelling a request.")]
    [StringLength(500, MinimumLength = 5, ErrorMessage = "Reason must be between 5 and 500 characters.")]
    public string Reason { get; set; } = string.Empty;
}

public class RejectProjectRequestDto
{
    [Required(ErrorMessage = "A rejection reason is required.")]
    [StringLength(500, MinimumLength = 5, ErrorMessage = "Rejection reason must be between 5 and 500 characters.")]
    public string RejectionReason { get; set; } = string.Empty;
}

// ─── Sub-DTOs ─────────────────────────────────────────────────────────────────

public record MoodboardImageDto(
    int Id,
    int ProjectRequestId,
    string ImageUrl,
    string ImageType,
    string? StorageKey,
    DateTime CreatedAtUtc
);

public record SuggestedPaletteDto(
    int Id,
    int ProjectRequestId,
    string HexCode,
    string ColorName,
    DateTime CreatedAtUtc
);

public record ProjectRequestStatusHistoryDto(
    int Id,
    string Status,
    string? Reason,
    string? ChangedBy,
    DateTime CreatedAtUtc
);

// ─── Query Filter & Analytics DTOs ──────────────────────────────────────────

public class ProjectRequestFilterQuery
{
    public string? Search { get; set; }
    public string? Status { get; set; }
    public string? RoomType { get; set; }
    public decimal? MinBudget { get; set; }
    public decimal? MaxBudget { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string? SortBy { get; set; } // "date_desc", "date_asc", "budget_desc", "budget_asc", "status"
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 10;
}

public class PagedResult<T>
{
    public IReadOnlyList<T> Items { get; set; } = new List<T>();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages => (int)Math.Ceiling((double)TotalCount / (PageSize > 0 ? PageSize : 10));
}

public class RequestAnalyticsDto
{
    public int TotalRequests { get; set; }
    public decimal AverageBudget { get; set; }
    public int PendingAiAnalysisCount { get; set; }
    public int FlaggedCount { get; set; }
    public Dictionary<string, int> RequestsByStatus { get; set; } = new();
    public Dictionary<string, int> RequestsByRoomType { get; set; } = new();
}

// ─── Response DTOs ────────────────────────────────────────────────────────────

public record ProjectRequestSummaryDto(
    int Id,
    string Title,
    string RoomType,
    decimal? RoomSize,
    string Status,
    DateTime CreatedAtUtc,
    string? Description,
    decimal? BudgetMin,
    decimal? BudgetMax,
    string? PreferredColours,
    string? SpecialRequirements,
    Guid ClientId,
    string? MainRoomPhotoUrl,
    int ImageCount
);

public record ProjectRequestDetailDto(
    int Id,
    Guid ClientId,
    string ClientName,
    string Title,
    string Description,
    string RoomType,
    decimal? RoomSize,
    decimal? BudgetMin,
    decimal? BudgetMax,
    DateTime? PreferredStartDate,
    DateTime? PreferredEndDate,
    string? StylePreferences,
    string? PreferredColours,
    string? SpecialRequirements,
    string Status,
    string? AssignedDesignerId,
    string? RejectionReason,
    string? FlagReason,
    List<MoodboardImageDto> Images,
    List<SuggestedPaletteDto> SuggestedPalettes,
    List<ProjectRequestStatusHistoryDto> StatusHistory,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc
);
