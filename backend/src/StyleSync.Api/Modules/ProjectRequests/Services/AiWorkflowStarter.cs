using System;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectRequests.Models.Entities;
using StyleSync.Api.Modules.ProjectRequests.Models.Enums;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;

namespace StyleSync.Api.Modules.ProjectRequests.Services;

public class AiWorkflowStarter : IWorkflowStarter
{
    private readonly ILogger<AiWorkflowStarter> _logger;
    private readonly IServiceProvider _serviceProvider;
    private readonly IHttpClientFactory _httpClientFactory;

    public AiWorkflowStarter(ILogger<AiWorkflowStarter> logger, IServiceProvider serviceProvider, IHttpClientFactory httpClientFactory)
    {
        _logger = logger;
        _serviceProvider = serviceProvider;
        _httpClientFactory = httpClientFactory;
    }

    public async Task StartAsync(Guid requestId)
    {
        _logger.LogInformation("Real workflow start requested for {id}", requestId);
        try
        {
            using var scope = _serviceProvider.CreateScope();
            var statusService = scope.ServiceProvider.GetRequiredService<RequestStatusService>();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            // 1. Transition to AIAnalysis
            await statusService.TransitionAsync(requestId, RequestStatus.AIAnalysis, null, "AI Style Analysis initiated");

            // 2. Fetch the request
            var request = await db.ProjectRequests
                .Include(r => r.MoodboardImages)
                .FirstOrDefaultAsync(r => r.Id == requestId);

            if (request == null)
            {
                _logger.LogWarning("Project request {id} not found.", requestId);
                return;
            }

            // 3. Prepare payload for Python AI service
            var payload = new
            {
                project_request_id = request.Id.ToString(),
                client_id = request.ClientId.ToString(),
                room_type = request.RoomType.ToString(),
                room_size = (float)request.RoomSizeSqFt,
                budget_min = (float)request.Budget,
                budget_max = (float)request.Budget,
                description = request.Description,
                room_photo_url = request.RoomPhotoUrl
            };

            // 4. Send to LangGraph
            var client = _httpClientFactory.CreateClient("AiService");
            var response = await client.PostAsJsonAsync("/workflow/run", payload);

            if (!response.IsSuccessStatusCode)
            {
                var error = await response.Content.ReadAsStringAsync();
                _logger.LogError("AI Service failed with {code}: {err}", response.StatusCode, error);
                // Fallback to manual review
                await statusService.TransitionAsync(requestId, RequestStatus.ProposalReady, null, "AI Failed - Manual review required");
                return;
            }

            var aiResult = await response.Content.ReadFromJsonAsync<AiWorkflowResponse>();

            // 5. Save the output to DB (Palettes, Style tags, etc)
            if (aiResult?.StyleProfile != null)
            {
                request.PaletteMode = "Generated";
                request.RequestedStyleTags = aiResult.StyleProfile.StyleTags ?? new List<string>();
                
                int pos = 1;
                foreach (var col in aiResult.StyleProfile.PreferredColours ?? new List<string>())
                {
                    db.SuggestedPalettes.Add(new SuggestedPalette
                    {
                        Id = Guid.NewGuid(),
                        ProjectRequestId = request.Id,
                        Hex = col,
                        Position = pos++,
                        Source = "AI Agent"
                    });
                }
            }

            // Move to ProposalReady -> AwaitingApproval
            await statusService.TransitionAsync(requestId, RequestStatus.ProposalReady, null, "AI workflow completed successfully");
            await statusService.TransitionAsync(requestId, RequestStatus.AwaitingApproval, null, "Proposal awaits admin approval");
            
            await db.SaveChangesAsync();
            _logger.LogInformation("Successfully completed AI workflow for {id}", requestId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to run AI workflow for request {id}", requestId);
        }
    }
}

public class AiWorkflowResponse
{
    public StyleProfileResponse? StyleProfile { get; set; }
}

public class StyleProfileResponse
{
    public List<string>? PreferredColours { get; set; }
    public List<string>? StyleTags { get; set; }
}
