using StyleSync.Backend.Domain.Enums;

namespace StyleSync.Backend.Domain.Entities;

public class ProjectRequest
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string ClientId { get; set; } = "client-default";
    public string RoomType { get; set; } = string.Empty; // e.g. Bedroom, Living Room, Kitchen
    public double LengthFeet { get; set; }
    public double WidthFeet { get; set; }
    public double HeightFeet { get; set; }
    public decimal BudgetLkr { get; set; }
    public List<string> PreferredStyles { get; set; } = new();
    public string Description { get; set; } = string.Empty;
    public ProjectRequestStatus Status { get; set; } = ProjectRequestStatus.Draft;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public bool IsDeleted { get; set; } = false;

    // Navigation properties
    public List<ProjectRequestPhoto> Photos { get; set; } = new();
    public StyleAnalysisResult? StyleAnalysis { get; set; }
}
