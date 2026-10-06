using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using StyleSync.Api.Modules.Designers.DTOs;

namespace StyleSync.Api.Modules.Designers.Services;

public interface IDesignerProfileService
{
    Task<IEnumerable<DesignerProfileDto>> GetAllAsync();
    Task<DesignerProfileDto?> GetByIdAsync(Guid id);
    Task<DesignerProfileDto?> GetByUserIdAsync(Guid userId);
    Task<DesignerProfileDto> CreateAsync(CreateDesignerProfileDto dto);
    Task<DesignerProfileDto?> UpdateAsync(Guid id, UpdateDesignerProfileDto dto);
    Task<bool> DeleteAsync(Guid id);
}
