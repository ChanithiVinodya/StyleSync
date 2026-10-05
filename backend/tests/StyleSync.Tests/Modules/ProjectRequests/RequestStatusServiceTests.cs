using System;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectRequests.Models.Entities;
using StyleSync.Api.Modules.ProjectRequests.Models.Enums;
using StyleSync.Api.Modules.ProjectRequests.Services;
using Xunit;

namespace StyleSync.Tests.Modules.ProjectRequests;

public class RequestStatusServiceTests
{
    private readonly AppDbContext _context;
    private readonly RequestStatusService _service;

    public RequestStatusServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        _context = new AppDbContext(options);
        _service = new RequestStatusService(_context);
    }

    [Theory]
    [InlineData(RequestStatus.Draft, RequestStatus.Submitted)]
    [InlineData(RequestStatus.Submitted, RequestStatus.AIAnalysis)]
    [InlineData(RequestStatus.AIAnalysis, RequestStatus.ProposalReady)]
    [InlineData(RequestStatus.ProposalReady, RequestStatus.AwaitingApproval)]
    [InlineData(RequestStatus.AwaitingApproval, RequestStatus.Approved)]
    [InlineData(RequestStatus.Approved, RequestStatus.DesignerAssigned)]
    [InlineData(RequestStatus.DesignerAssigned, RequestStatus.InProgress)]
    [InlineData(RequestStatus.InProgress, RequestStatus.Completed)]
    public async Task TransitionAsync_LegalTransitions_Passes(RequestStatus from, RequestStatus to)
    {
        var request = new ProjectRequest { Id = Guid.NewGuid(), Status = from };
        _context.ProjectRequests.Add(request);
        await _context.SaveChangesAsync();

        await _service.TransitionAsync(request.Id, to);

        var updatedRequest = await _context.ProjectRequests.FindAsync(request.Id);
        Assert.Equal(to, updatedRequest!.Status);
        
        var historyCount = await _context.RequestStatusHistories.CountAsync(h => h.ProjectRequestId == request.Id);
        Assert.Equal(1, historyCount);
    }

    [Fact]
    public async Task TransitionAsync_DraftToInProgress_Fails()
    {
        var request = new ProjectRequest { Id = Guid.NewGuid(), Status = RequestStatus.Draft };
        _context.ProjectRequests.Add(request);
        await _context.SaveChangesAsync();

        await Assert.ThrowsAsync<IllegalStatusTransitionException>(() => 
            _service.TransitionAsync(request.Id, RequestStatus.InProgress));
    }

    [Theory]
    [InlineData(RequestStatus.Completed)]
    [InlineData(RequestStatus.Rejected)]
    [InlineData(RequestStatus.Cancelled)]
    public async Task TransitionAsync_TerminalStatesToAnything_Fails(RequestStatus terminalStatus)
    {
        var request = new ProjectRequest { Id = Guid.NewGuid(), Status = terminalStatus };
        _context.ProjectRequests.Add(request);
        await _context.SaveChangesAsync();

        // Testing transition to some random state
        await Assert.ThrowsAsync<IllegalStatusTransitionException>(() => 
            _service.TransitionAsync(request.Id, RequestStatus.Submitted));
            
        await Assert.ThrowsAsync<IllegalStatusTransitionException>(() => 
            _service.TransitionAsync(request.Id, RequestStatus.Cancelled));
    }
    
    [Fact]
    public async Task TransitionAsync_SuccessfulTransition_WritesOneHistoryRow()
    {
        var request = new ProjectRequest { Id = Guid.NewGuid(), Status = RequestStatus.Draft };
        _context.ProjectRequests.Add(request);
        await _context.SaveChangesAsync();
        
        var userId = Guid.NewGuid();
        var note = "Test transition";

        await _service.TransitionAsync(request.Id, RequestStatus.Submitted, userId, note);

        var histories = await _context.RequestStatusHistories.ToListAsync();
        Assert.Single(histories);
        
        var history = histories[0];
        Assert.Equal(request.Id, history.ProjectRequestId);
        Assert.Equal(RequestStatus.Draft, history.FromStatus);
        Assert.Equal(RequestStatus.Submitted, history.ToStatus);
        Assert.Equal(userId, history.ChangedByUserId);
        Assert.Equal(note, history.Note);
    }
}
