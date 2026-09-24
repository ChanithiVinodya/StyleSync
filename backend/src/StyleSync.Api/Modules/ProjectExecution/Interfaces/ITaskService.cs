using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using StyleSync.Api.Modules.ProjectExecution.DTOs;
using StyleSync.Api.Modules.ProjectExecution.Models;

namespace StyleSync.Api.Modules.ProjectExecution.Interfaces;

public interface ITaskService
{
    Task<IEnumerable<TaskDto>> GetAllAsync(Guid? milestoneId, Models.TaskStatus? status);
    Task<TaskDto?> GetByIdAsync(Guid id);
    Task<TaskDto> CreateAsync(CreateTaskDto request);
    Task<TaskDto?> UpdateAsync(Guid id, UpdateTaskDto request);
    Task<bool> DeleteAsync(Guid id);
}
