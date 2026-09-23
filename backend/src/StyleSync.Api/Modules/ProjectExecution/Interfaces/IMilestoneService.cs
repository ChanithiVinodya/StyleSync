using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using StyleSync.Api.Modules.ProjectExecution.DTOs;
using StyleSync.Api.Modules.ProjectExecution.Models;

namespace StyleSync.Api.Modules.ProjectExecution.Interfaces;

public interface IMilestoneService
{
    Task<IEnumerable<MilestoneDto>> GetAllAsync(Guid? projectId, MilestoneStatus? status);
    Task<MilestoneDto?> GetByIdAsync(Guid id);
    Task<MilestoneDto> CreateAsync(CreateMilestoneDto request);
    Task<MilestoneDto?> UpdateAsync(Guid id, UpdateMilestoneDto request);
    Task<bool> DeleteAsync(Guid id);
}
