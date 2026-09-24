using System.Collections.Generic;
using System.Threading.Tasks;
using StyleSync.Api.Modules.ProjectExecution.DTOs;

namespace StyleSync.Api.Modules.ProjectExecution.Interfaces;

public interface IDelayService
{
    Task<IEnumerable<DelayedTaskDto>> GetDelayedTasksAsync();
    Task<DelayDetectionResultDto> RunDelayDetectionAsync();
}
