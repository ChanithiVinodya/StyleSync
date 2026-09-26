using System;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace StyleSync.Api.Modules.ProjectExecution.DTOs;

public class CreateProgressPhotoDto
{
    [Required]
    public IFormFile File { get; set; } = null!;

    [Required]
    public Guid ProjectId { get; set; }

    public Guid? MilestoneId { get; set; }

    public Guid? TaskId { get; set; }

    [MaxLength(500)]
    public string? Caption { get; set; }
}
