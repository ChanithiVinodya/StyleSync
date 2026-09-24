using System.ComponentModel.DataAnnotations;
using StyleSync.Api.Modules.ProjectExecution.Models;

namespace StyleSync.Api.Modules.ProjectExecution.DTOs;

public class UpdateMaterialStatusDto
{
    [Required]
    public MaterialStatus Status { get; set; }
}
