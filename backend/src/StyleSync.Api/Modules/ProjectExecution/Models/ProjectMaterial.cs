using System;

namespace StyleSync.Api.Modules.ProjectExecution.Models;

public class ProjectMaterial
{
    public Guid MaterialId { get; set; }
    
    public Guid ProjectId { get; set; }
    
    // A Material can optionally be associated with a milestone
    public Guid? MilestoneId { get; set; }
    public ProjectMilestone? Milestone { get; set; }
    
    public string Name { get; set; } = string.Empty;
    
    public int Quantity { get; set; }
    
    public DateTime? ExpectedDeliveryDate { get; set; }
    
    public MaterialStatus Status { get; set; }
    
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
