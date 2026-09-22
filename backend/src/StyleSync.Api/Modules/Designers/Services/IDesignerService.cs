using StyleSync.Api.Modules.Designers.DTOs;

namespace StyleSync.Api.Modules.Designers.Services;

public interface IDesignerService
{
    Task<DesignerProfileResponse?> GetProfileByIdAsync(int id, bool includeUnpublished = false);
    Task<DesignerProfileResponse> CreateProfileAsync(int currentUserId, bool isAdmin, CreateDesignerProfileRequest request);
    Task<DesignerProfileResponse> UpdateProfileAsync(int id, int currentUserId, bool isAdmin, UpdateDesignerProfileRequest request);
    Task<bool> ArchiveProfileAsync(int id, bool isAdmin);
    Task<PortfolioItemResponse> AddPortfolioItemAsync(int designerId, int currentUserId, bool isAdmin, CreatePortfolioItemRequest request);
    Task<List<PortfolioItemResponse>> GetPortfolioItemsAsync(int designerId, bool publicOnly = true);
    Task<bool> DeletePortfolioItemAsync(int designerId, int itemId, int currentUserId, bool isAdmin);
}
