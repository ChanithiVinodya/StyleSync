using System;

namespace StyleSync.Api.Modules.ProjectExecution.DTOs;

public class ProgressPhotoDto
{
    public Guid ProgressPhotoId { get; set; }
    public Guid ProjectId { get; set; }
    public Guid? MilestoneId { get; set; }
    public Guid UploadedBy { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime UploadedAt { get; set; }
}
