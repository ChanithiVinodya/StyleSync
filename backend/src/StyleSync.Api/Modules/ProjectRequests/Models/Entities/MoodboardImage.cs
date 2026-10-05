using System;

namespace StyleSync.Api.Modules.ProjectRequests.Models.Entities;

public class MoodboardImage
{
    public Guid Id { get; set; } = Guid.NewGuid();
    
    public Guid ProjectRequestId { get; set; }
    public ProjectRequest ProjectRequest { get; set; } = null!;
    
    public string Url { get; set; } = string.Empty;
    public string StorageKey { get; set; } = string.Empty;
    
    public int SortOrder { get; set; }
    
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
}
