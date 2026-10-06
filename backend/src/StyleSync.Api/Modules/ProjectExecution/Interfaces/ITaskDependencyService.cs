using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using StyleSync.Api.Modules.ProjectExecution.DTOs;

namespace StyleSync.Api.Modules.ProjectExecution.Interfaces;

public interface ITaskDependencyService
{
    Task<TaskDependencyDto> CreateDependencyAsync(Guid taskId, CreateTaskDependencyDto request);
    Task<IEnumerable<TaskDependencyTaskDto>> GetPrerequisitesAsync(Guid taskId);
    Task<IEnumerable<TaskDependencyTaskDto>> GetDependentsAsync(Guid taskId);
    Task<bool> DeleteDependencyAsync(Guid taskId, Guid prerequisiteTaskId);
}
