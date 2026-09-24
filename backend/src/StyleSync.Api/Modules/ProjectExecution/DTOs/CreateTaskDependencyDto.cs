using System;
using System.ComponentModel.DataAnnotations;

namespace StyleSync.Api.Modules.ProjectExecution.DTOs;

public class CreateTaskDependencyDto
{
    [Required]
    public Guid PrerequisiteTaskId { get; set; }
}
