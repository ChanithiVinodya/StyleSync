using System;
using System.ComponentModel.DataAnnotations;
using StyleSync.Api.Modules.ProjectExecution.Models;

namespace StyleSync.Api.Modules.ProjectExecution.DTOs;

public class UpdateMilestoneDto
{
    [Required]
    [StringLength(200, MinimumLength = 1)]
    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    [Required]
    public DateTime StartDate { get; set; }

    [Required]
    public DateTime DueDate { get; set; }

    [Required]
    public MilestoneStatus Status { get; set; }
}
