using System;
using System.ComponentModel.DataAnnotations;

namespace StyleSync.Api.Modules.ProjectExecution.DTOs;

public class UpdateMaterialDto
{
    public Guid? MilestoneId { get; set; }
    public Guid? TaskId { get; set; }
    
    [Required]
    [StringLength(200, MinimumLength = 1)]
    public string Name { get; set; } = string.Empty;
    
    [StringLength(1000)]
    public string? Description { get; set; }
    
    [Range(1, int.MaxValue)]
    public int Quantity { get; set; }
    
    [Required]
    [StringLength(50, MinimumLength = 1)]
    public string Unit { get; set; } = string.Empty;
    
    public DateTime? RequiredDate { get; set; }
}
