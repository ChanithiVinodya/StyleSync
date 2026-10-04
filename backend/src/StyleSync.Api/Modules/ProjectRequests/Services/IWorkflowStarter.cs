using System;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;

namespace StyleSync.Api.Modules.ProjectRequests.Services;

public interface IWorkflowStarter
{
    Task StartAsync(Guid requestId);
}

public class MockWorkflowStarter : IWorkflowStarter
{
    private readonly ILogger<MockWorkflowStarter> _logger;

    public MockWorkflowStarter(ILogger<MockWorkflowStarter> logger)
    {
        _logger = logger;
    }

    public Task StartAsync(Guid requestId)
    {
        _logger.LogInformation("workflow start requested for {id}", requestId);
        return Task.CompletedTask;
    }
}
