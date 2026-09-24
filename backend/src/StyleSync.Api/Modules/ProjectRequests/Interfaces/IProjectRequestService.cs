using StyleSync.Api.Modules.ProjectRequests.DTOs;

namespace StyleSync.Api.Modules.ProjectRequests.Interfaces;

public interface IProjectRequestService
{
    /// <summary>Submit a new project request (Client only).</summary>
    Task<ProjectRequestDetailDto> CreateAsync(Guid clientId, CreateProjectRequestDto dto);

    /// <summary>Get all requests submitted by a specific client.</summary>
    Task<IReadOnlyList<ProjectRequestSummaryDto>> GetByClientAsync(Guid clientId);

    /// <summary>Get all requests (Admin/Designer view).</summary>
    Task<IReadOnlyList<ProjectRequestSummaryDto>> GetAllAsync();

    /// <summary>Get a single request by ID, enforcing ownership or admin access.</summary>
    Task<ProjectRequestDetailDto> GetByIdAsync(int requestId, Guid requestingUserId, string requestingUserRole);

    /// <summary>Update draft/submitted request fields (Client, own requests only).</summary>
    Task<ProjectRequestDetailDto> UpdateAsync(int requestId, Guid clientId, UpdateProjectRequestDto dto);

    /// <summary>Cancel a pending request (Client, own requests only).</summary>
    Task CancelAsync(int requestId, Guid clientId);

    /// <summary>Admin: transition request status (UnderReview, QuoteProvided, Accepted, Rejected).</summary>
    Task<ProjectRequestDetailDto> UpdateStatusAsync(int requestId, string newStatus, string? rejectionReason);
}
