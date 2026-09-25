using System.ComponentModel.DataAnnotations;
using StyleSync.Api.Modules.ProjectRequests.Models;

namespace StyleSync.Api.Modules.ProjectRequests.DTOs;

// ─── Request DTOs ─────────────────────────────────────────────────────────────

public class CreateProjectRequestDto
{
    [Required(ErrorMessage = "Title is required.")]
    [StringLength(150, MinimumLength = 5, ErrorMessage = "Title must be between 5 and 150 characters.")]
    public string Title { get; set; } = string.Empty;

    [Required(ErrorMessage = "Description is required.")]
    [StringLength(2000, MinimumLength = 20, ErrorMessage = "Description must be between 20 and 2000 characters.")]
    public string Description { get; set; } = string.Empty;

    [Required(ErrorMessage = "Room type is required.")]
    public RoomType RoomType { get; set; }

    [Range(0, 10_000_000, ErrorMessage = "Budget minimum must be a positive value.")]
    public decimal? BudgetMin { get; set; }

    [Range(0, 10_000_000, ErrorMessage = "Budget maximum must be a positive value.")]
    public decimal? BudgetMax { get; set; }

    public DateTime? PreferredStartDate { get; set; }
    public DateTime? PreferredEndDate { get; set; }

    [StringLength(500, ErrorMessage = "Style preferences cannot exceed 500 characters.")]
    public string? StylePreferences { get; set; }

    [StringLength(1000, ErrorMessage = "Special requirements cannot exceed 1000 characters.")]
    public string? SpecialRequirements { get; set; }

    /// <summary>If true, the request is immediately moved to Submitted status. If false, it stays as Draft.</summary>
    public bool SubmitImmediately { get; set; } = false;
}

public class UpdateProjectRequestDto
{
    [StringLength(150, MinimumLength = 5, ErrorMessage = "Title must be between 5 and 150 characters.")]
    public string? Title { get; set; }

    [StringLength(2000, MinimumLength = 20, ErrorMessage = "Description must be between 20 and 2000 characters.")]
    public string? Description { get; set; }

    public RoomType? RoomType { get; set; }

    [Range(0, 10_000_000)]
    public decimal? BudgetMin { get; set; }

    [Range(0, 10_000_000)]
    public decimal? BudgetMax { get; set; }

    public DateTime? PreferredStartDate { get; set; }
    public DateTime? PreferredEndDate { get; set; }

    [StringLength(500)]
    public string? StylePreferences { get; set; }

    [StringLength(1000)]
    public string? SpecialRequirements { get; set; }
}

public class RejectProjectRequestDto
{
    [Required(ErrorMessage = "A rejection reason is required.")]
    [StringLength(500, MinimumLength = 10, ErrorMessage = "Rejection reason must be between 10 and 500 characters.")]
    public string RejectionReason { get; set; } = string.Empty;
}

// ─── Response DTOs ────────────────────────────────────────────────────────────

public record ProjectRequestSummaryDto(
    int Id,
    string Title,
    string RoomType,
    string Status,
    DateTime CreatedAtUtc,
    string? Description,
    decimal? BudgetMin,
    decimal? BudgetMax,
    string? SpecialRequirements,
    Guid ClientId
);

public record ProjectRequestDetailDto(
    int Id,
    Guid ClientId,
    string ClientName,
    string Title,
    string Description,
    string RoomType,
    decimal? BudgetMin,
    decimal? BudgetMax,
    DateTime? PreferredStartDate,
    DateTime? PreferredEndDate,
    string? StylePreferences,
    string? SpecialRequirements,
    string Status,
    string? AssignedDesignerId,
    string? RejectionReason,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc
);
