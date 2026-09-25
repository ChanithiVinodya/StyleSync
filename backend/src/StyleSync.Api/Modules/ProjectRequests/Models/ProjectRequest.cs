using StyleSync.Api.Common.Shared;
using StyleSync.Api.Common.Identity;

namespace StyleSync.Api.Modules.ProjectRequests.Models;

public enum ProjectRequestStatus
{
    Draft,
    Submitted,
    UnderReview,
    QuoteProvided,
    Accepted,
    Rejected,
    Cancelled
}

public enum RoomType
{
    LivingRoom,
    Bedroom,
    Kitchen,
    Bathroom,
    Office,
    DiningRoom,
    Outdoor,
    Other
}

public class ProjectRequest : BaseEntity
{
    // BaseEntity provides:  int Id, DateTime CreatedAtUtc, DateTime? UpdatedAtUtc

    public Guid ClientId { get; set; }
    public AppUser Client { get; set; } = null!;

    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public RoomType RoomType { get; set; }

    public decimal? BudgetMin { get; set; }
    public decimal? BudgetMax { get; set; }

    public DateTime? PreferredStartDate { get; set; }
    public DateTime? PreferredEndDate { get; set; }

    public string? StylePreferences { get; set; }
    public string? SpecialRequirements { get; set; }

    public ProjectRequestStatus Status { get; set; } = ProjectRequestStatus.Draft;

    public string? AssignedDesignerId { get; set; }
    public string? RejectionReason { get; set; }
}
