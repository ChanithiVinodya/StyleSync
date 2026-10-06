using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using StyleSync.Api.Modules.ProjectExecution.DTOs;

namespace StyleSync.Api.Modules.ProjectExecution.Interfaces;

public interface IMaterialService
{
    Task<MaterialDto> CreateAsync(CreateMaterialDto request);
    Task<IEnumerable<MaterialDto>> GetAllAsync(Guid? projectId = null, Guid? milestoneId = null, Guid? taskId = null, string? status = null);
    Task<MaterialDto?> GetByIdAsync(Guid materialId);
    Task<MaterialDto?> UpdateAsync(Guid materialId, UpdateMaterialDto request);
    Task<bool> DeleteAsync(Guid materialId);
    Task<MaterialDto?> UpdateStatusAsync(Guid materialId, UpdateMaterialStatusDto request);
}
