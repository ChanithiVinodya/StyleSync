namespace StyleSync.Backend.Domain.Entities;

public class ProjectRequestPhoto
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ProjectRequestId { get; set; }
    public string PhotoUrl { get; set; } = string.Empty;
    public string StorageKey { get; set; } = string.Empty;
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
}
