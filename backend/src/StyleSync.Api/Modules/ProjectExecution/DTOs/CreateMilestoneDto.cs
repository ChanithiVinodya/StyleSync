using System;
using System.ComponentModel.DataAnnotations;

namespace StyleSync.Api.Modules.ProjectExecution.DTOs;

public class CreateMilestoneDto
{
    [Required]
    public Guid ProjectId { get; set; }

    [Required]
    [StringLength(200, MinimumLength = 1)]
    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    [Required]
    public DateTime StartDate { get; set; }

    [Required]
    public DateTime DueDate { get; set; }
}
