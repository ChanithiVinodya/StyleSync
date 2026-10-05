using Microsoft.Extensions.DependencyInjection;
using StyleSync.Api.Modules.ProjectRequests.Models.Enums;

namespace StyleSync.Api.Modules.ProjectRequests.Services;

public interface IWorkflowStarter
{
    Task StartAsync(Guid requestId);
}

public class MockWorkflowStarter : IWorkflowStarter
{
    private readonly ILogger<MockWorkflowStarter> _logger;
    private readonly IServiceProvider _serviceProvider;

    public MockWorkflowStarter(ILogger<MockWorkflowStarter> logger, IServiceProvider serviceProvider)
    {
        _logger = logger;
        _serviceProvider = serviceProvider;
    }

    public async Task StartAsync(Guid requestId)
    {
        _logger.LogInformation("workflow start requested for {id}", requestId);
        try
        {
            using var scope = _serviceProvider.CreateScope();
            var statusService = scope.ServiceProvider.GetRequiredService<RequestStatusService>();
            await statusService.TransitionAsync(requestId, RequestStatus.AIAnalysis, null, "AI Style Analysis initiated");
            _logger.LogInformation("Request {id} transitioned to AIAnalysis", requestId);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to transition request {id} to AIAnalysis", requestId);
        }
    }
}
