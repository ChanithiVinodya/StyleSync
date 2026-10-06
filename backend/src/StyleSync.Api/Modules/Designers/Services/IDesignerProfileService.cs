using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using StyleSync.Api.Modules.Designers.DTOs;

namespace StyleSync.Api.Modules.Designers.Services;

public interface IDesignerProfileService
{
    Task<IEnumerable<DesignerProfileResponse>> GetAllAsync();
    Task<DesignerProfileResponse?> GetByIdAsync(int id);
    Task<DesignerProfileResponse?> GetByUserIdAsync(Guid userId);
    Task<DesignerProfileResponse> CreateAsync(CreateDesignerProfileRequest dto);
    Task<DesignerProfileResponse?> UpdateAsync(int id, UpdateDesignerProfileRequest dto);
    Task<bool> DeleteAsync(int id);
}
