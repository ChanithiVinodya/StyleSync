using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using StyleSync.Api.Modules.ProjectExecution.DTOs;

namespace StyleSync.Api.Modules.ProjectExecution.Interfaces;

public interface IProgressPhotoService
{
    Task<ProgressPhotoDto> CreateAsync(CreateProgressPhotoDto request, Guid userId);
    Task<ProgressPhotoDto?> GetByIdAsync(Guid photoId);
    Task<IEnumerable<ProgressPhotoDto>> GetProjectPhotosAsync(Guid projectId, Guid? milestoneId = null, Guid? taskId = null, DateTime? from = null, DateTime? to = null, string sort = "desc");
    Task<ProgressPhotoDto?> UpdateAsync(Guid photoId, UpdateProgressPhotoDto request);
    Task<bool> DeleteAsync(Guid photoId);
}
