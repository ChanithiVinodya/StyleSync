using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using StyleSync.Api.Modules.ProjectExecution.DTOs;

namespace StyleSync.Api.Modules.ProjectExecution.Interfaces;

public interface IProjectTimelineService
{
    Task<IEnumerable<ProjectTimelineEventDto>> GetProjectTimelineAsync(Guid projectId, string? eventType = null, DateTime? from = null, DateTime? to = null);
}
