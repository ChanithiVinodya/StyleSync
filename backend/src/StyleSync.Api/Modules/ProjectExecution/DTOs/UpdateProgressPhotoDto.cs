using System;
using System.ComponentModel.DataAnnotations;

namespace StyleSync.Api.Modules.ProjectExecution.DTOs;

public class UpdateProgressPhotoDto
{
    [MaxLength(500)]
    public string? Caption { get; set; }

    public Guid? MilestoneId { get; set; }

    public Guid? TaskId { get; set; }
}
