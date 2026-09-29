using StyleSync.Api.Modules.ProjectRequests.DTOs;

namespace StyleSync.Api.Modules.ProjectRequests.Interfaces;

public interface IProjectRequestService
{
    /// <summary>Create a draft or submit a new project request (Client only).</summary>
    Task<ProjectRequestDetailDto> CreateAsync(Guid clientId, CreateProjectRequestDto dto);

    /// <summary>Get requests submitted by a specific client or all requests for admin, with filter, sort, pagination.</summary>
    Task<PagedResult<ProjectRequestSummaryDto>> GetFilteredAsync(Guid requestingUserId, string requestingUserRole, ProjectRequestFilterQuery query);

    /// <summary>Get all requests legacy list.</summary>
    Task<IReadOnlyList<ProjectRequestSummaryDto>> GetByClientAsync(Guid clientId);
    Task<IReadOnlyList<ProjectRequestSummaryDto>> GetAllAsync();

    /// <summary>Get a single request by ID, enforcing ownership or admin access.</summary>
    Task<ProjectRequestDetailDto> GetByIdAsync(int requestId, Guid requestingUserId, string requestingUserRole);

    /// <summary>Update draft request fields (Client, own requests only).</summary>
    Task<ProjectRequestDetailDto> UpdateAsync(int requestId, Guid clientId, UpdateProjectRequestDto dto);

    /// <summary>Delete a draft request (Client, own requests only).</summary>
    Task DeleteAsync(int requestId, Guid clientId);

    /// <summary>Upload photo or moodboard images to request.</summary>
    Task<ProjectRequestDetailDto> AddImagesAsync(int requestId, Guid clientId, List<UploadImageDto> images);

    /// <summary>Cancel a pending request (Client or Admin).</summary>
    Task CancelAsync(int requestId, Guid clientId, string? reason = null);

    /// <summary>Submit a draft request (Client, own requests only). Enforces validation: ownership, budget > 0, room size > 0, at least 1 photo exists.</summary>
    Task<ProjectRequestDetailDto> SubmitAsync(int requestId, Guid clientId);

    /// <summary>Admin: Flag or cancel invalid request with reason stored for audit trail.</summary>
    Task<ProjectRequestDetailDto> FlagRequestAsync(int requestId, string reason, string adminName);

    /// <summary>Admin: transition request status along AI / Admin workflow.</summary>
    Task<ProjectRequestDetailDto> UpdateStatusAsync(int requestId, string newStatus, string? rejectionReason);

    /// <summary>Admin Analytics cards feed: requests by status, room type, average budget.</summary>
    Task<RequestAnalyticsDto> GetAnalyticsAsync();
}
