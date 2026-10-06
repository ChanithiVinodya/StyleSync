using System;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectRequests.Models.Entities;
using StyleSync.Api.Modules.ProjectRequests.Models.Enums;

namespace StyleSync.Api.Modules.ProjectRequests.Services;

public class IllegalStatusTransitionException : Exception
{
    public IllegalStatusTransitionException(string message) : base(message) { }
}

public class RequestStatusService
{
    private readonly AppDbContext _context;

    public RequestStatusService(AppDbContext context)
    {
        _context = context;
    }

    public async Task TransitionAsync(Guid requestId, RequestStatus toStatus, Guid? changedByUserId = null, string? note = null)
    {
        var request = await _context.ProjectRequests.FirstOrDefaultAsync(r => r.Id == requestId);
        if (request == null)
            throw new Exception("Request not found");

        var fromStatus = request.Status;

        if (!IsValidTransition(fromStatus, toStatus))
        {
            throw new IllegalStatusTransitionException($"Cannot transition from {fromStatus} to {toStatus}");
        }

        request.Status = toStatus;
        request.UpdatedAt = DateTime.UtcNow;

        var validChangedByUserId = (changedByUserId.HasValue && changedByUserId.Value != Guid.Empty) 
            ? changedByUserId 
            : null;

        var history = new RequestStatusHistory
        {
            ProjectRequestId = requestId,
            FromStatus = fromStatus,
            ToStatus = toStatus,
            ChangedAt = DateTime.UtcNow,
            ChangedByUserId = validChangedByUserId,
            Note = note
        };

        _context.RequestStatusHistories.Add(history);
        await _context.SaveChangesAsync();
    }

    private bool IsValidTransition(RequestStatus from, RequestStatus to)
    {
        if (from == RequestStatus.Completed || from == RequestStatus.Rejected || from == RequestStatus.Cancelled)
        {
            return false;
        }

        if (to == RequestStatus.Rejected || to == RequestStatus.Cancelled)
        {
            return true;
        }

        return from switch
        {
            RequestStatus.Draft => to == RequestStatus.Submitted,
            RequestStatus.Submitted => to == RequestStatus.AIAnalysis,
            RequestStatus.AIAnalysis => to == RequestStatus.ProposalReady,
            RequestStatus.ProposalReady => to == RequestStatus.AwaitingApproval,
            RequestStatus.AwaitingApproval => to == RequestStatus.Approved,
            RequestStatus.Approved => to == RequestStatus.DesignerAssigned,
            RequestStatus.DesignerAssigned => to == RequestStatus.InProgress,
            RequestStatus.InProgress => to == RequestStatus.Completed,
            _ => false
        };
    }
}
