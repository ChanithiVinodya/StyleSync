using StyleSync.Api.Common.Shared;

namespace StyleSync.Api.Modules.ProjectRequests.Models;

public class MoodboardImage : BaseEntity
{
    public int ProjectRequestId { get; set; }
    public ProjectRequest ProjectRequest { get; set; } = null!;

    public string ImageUrl { get; set; } = string.Empty;
    public string ImageType { get; set; } = "Moodboard"; // "RoomPhoto" or "Moodboard"
    public string? StorageKey { get; set; }
}
