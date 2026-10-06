using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace StyleSync.Api.Modules.ProjectExecution.Models;

public class ProjectTimelineEvent
{
    [Key]
    public Guid TimelineEventId { get; set; }
    
    public Guid ProjectId { get; set; }
    
    [Required]
    [MaxLength(100)]
    public string EventType { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(255)]
    public string Title { get; set; } = string.Empty;
    
    public string? Description { get; set; }
    
    public DateTime Timestamp { get; set; }
    
    public Guid? CreatedBy { get; set; }
}
