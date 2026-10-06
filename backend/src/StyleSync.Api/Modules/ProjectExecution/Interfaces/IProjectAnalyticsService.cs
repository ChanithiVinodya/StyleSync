using System;
using System.Threading.Tasks;
using StyleSync.Api.Modules.ProjectExecution.DTOs;

namespace StyleSync.Api.Modules.ProjectExecution.Interfaces;

public interface IProjectAnalyticsService
{
    Task<ProjectAnalyticsDto> GetProjectAnalyticsAsync(Guid projectId, DateTime? from = null, DateTime? to = null);
}
