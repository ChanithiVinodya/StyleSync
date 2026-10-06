using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;
using System.Collections.Concurrent;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.TestHost;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectRequests.Models.Entities;
using StyleSync.Api.Modules.ProjectRequests.Models.Enums;
using StyleSync.Api.Modules.ProjectRequests.Services;
using StyleSync.Api.Common.Identity;
using Xunit;
using Microsoft.EntityFrameworkCore;
using System.Threading;

namespace StyleSync.Tests.Modules.ProjectRequests;

public class TestWorkflowStarter : IWorkflowStarter
{
    public int CallCount = 0;
    public Task StartAsync(Guid requestId)
    {
        Interlocked.Increment(ref CallCount);
        return Task.CompletedTask;
    }
}

public class SubmitIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly TestWorkflowStarter _spy = new();

    public SubmitIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureTestServices(services =>
            {
                var descriptor = services.SingleOrDefault(d => d.ServiceType == typeof(DbContextOptions<AppDbContext>));
                if (descriptor != null) services.Remove(descriptor);
                
                var dbName = "InMemoryDbForSubmitTesting" + Guid.NewGuid().ToString();
                services.AddDbContext<AppDbContext>(options =>
                {
                    options.UseInMemoryDatabase(dbName);
                });

                var ws = services.SingleOrDefault(d => d.ServiceType == typeof(IWorkflowStarter));
                if (ws != null) services.Remove(ws);
                services.AddSingleton<IWorkflowStarter>(_spy);

                services.AddAuthentication(TestAuthHandler.AuthenticationScheme)
                        .AddScheme<Microsoft.AspNetCore.Authentication.AuthenticationSchemeOptions, TestAuthHandler>(TestAuthHandler.AuthenticationScheme, options => { });

                services.Configure<Microsoft.AspNetCore.Authentication.AuthenticationOptions>(o => 
                {
                    o.DefaultAuthenticateScheme = TestAuthHandler.AuthenticationScheme;
                    o.DefaultChallengeScheme = TestAuthHandler.AuthenticationScheme;
                });
            });
        });
    }

    private HttpClient CreateClient(string roleAndIdentifier = "Client1")
    {
        var client = _factory.CreateClient(new WebApplicationFactoryClientOptions { AllowAutoRedirect = false });
        if (roleAndIdentifier != "None")
        {
            client.DefaultRequestHeaders.Add("Authorization", $"Bearer {roleAndIdentifier}");
        }
        return client;
    }

    private async Task<Guid> SeedDraftRequest(Guid clientId, RequestStatus status = RequestStatus.Draft, decimal budget = 15000m, decimal roomSize = 200m, string? photoUrl = "http://photo.jpg")
    {
        Guid reqId = Guid.NewGuid();
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        if (!db.Users.Any(u => u.Id == clientId))
        {
            db.Users.Add(new AppUser { Id = clientId, Email = "c@test.com", Name = "c", PasswordHash = "x", Role = UserRole.Client });
        }
        db.ProjectRequests.Add(new ProjectRequest
        {
            Id = reqId,
            ClientId = clientId,
            Status = status,
            Budget = budget,
            RoomSizeSqFt = roomSize,
            RoomType = RoomType.LivingRoom,
            Description = "This is a valid description.",
            RoomPhotoUrl = photoUrl
        });
        await db.SaveChangesAsync();
        return reqId;
    }

    [Fact]
    public async Task Submit_HappyPath()
    {
        _spy.CallCount = 0;
        var clientId = Guid.Parse("11111111-1111-1111-1111-111111111111");
        var reqId = await SeedDraftRequest(clientId);
        var client = CreateClient("Client1");

        var res = await client.PostAsync($"/requests/{reqId}/submit", null);
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var req = await db.ProjectRequests.Include(r => r.StatusHistories).FirstAsync(r => r.Id == reqId);
        
        Assert.Equal(RequestStatus.Submitted, req.Status);
        Assert.NotNull(req.SubmittedAt);
        Assert.Single(req.StatusHistories);
        Assert.Equal(1, _spy.CallCount);
    }

    [Fact]
    public async Task Submit_AnotherClient_Returns404()
    {
        var clientId = Guid.Parse("11111111-1111-1111-1111-111111111111");
        var reqId = await SeedDraftRequest(clientId);
        
        var client = CreateClient("Client2"); // ID 22222222-2222-2222-2222-222222222222
        var res = await client.PostAsync($"/requests/{reqId}/submit", null);
        Assert.Equal(HttpStatusCode.NotFound, res.StatusCode);
    }
    
    [Fact]
    public async Task Submit_Admin_Returns403()
    {
        var clientId = Guid.Parse("11111111-1111-1111-1111-111111111111");
        var reqId = await SeedDraftRequest(clientId);
        
        var client = CreateClient("Admin");
        var res = await client.PostAsync($"/requests/{reqId}/submit", null);
        Assert.Equal(HttpStatusCode.Forbidden, res.StatusCode);
    }

    [Fact]
    public async Task Submit_AlreadySubmitted_Returns409()
    {
        var clientId = Guid.Parse("11111111-1111-1111-1111-111111111111");
        var reqId = await SeedDraftRequest(clientId, status: RequestStatus.Submitted);
        var client = CreateClient("Client1");

        var res = await client.PostAsync($"/requests/{reqId}/submit", null);
        Assert.Equal(HttpStatusCode.Conflict, res.StatusCode);
    }

    [Fact]
    public async Task Submit_MissingPhotoAndInvalidBudget_Returns400WithAllErrors()
    {
        var clientId = Guid.Parse("11111111-1111-1111-1111-111111111111");
        var reqId = await SeedDraftRequest(clientId, budget: 0m, roomSize: 0m, photoUrl: null);
        var client = CreateClient("Client1");

        var res = await client.PostAsync($"/requests/{reqId}/submit", null);
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);

        var content = await res.Content.ReadAsStringAsync();
        Assert.Contains("ROOM_PHOTO_REQUIRED", content);
        Assert.Contains("BUDGET_NOT_POSITIVE", content);
        Assert.Contains("ROOM_SIZE_INVALID", content);
        
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var req = await db.ProjectRequests.Include(r => r.StatusHistories).FirstAsync(r => r.Id == reqId);
        
        Assert.Equal(RequestStatus.Draft, req.Status); // Remains draft
        Assert.Empty(req.StatusHistories); // No history row
    }

    [Fact]
    public async Task Submit_Concurrent_ResultsInOneSuccess()
    {
        _spy.CallCount = 0;
        var clientId = Guid.Parse("11111111-1111-1111-1111-111111111111");
        var reqId = await SeedDraftRequest(clientId);
        
        var client1 = CreateClient("Client1");
        var client2 = CreateClient("Client1");

        var task1 = client1.PostAsync($"/requests/{reqId}/submit", null);
        var task2 = client2.PostAsync($"/requests/{reqId}/submit", null);

        var results = await Task.WhenAll(task1, task2);
        
        Assert.Contains(results, r => r.StatusCode == HttpStatusCode.OK);
        Assert.Contains(results, r => r.StatusCode == HttpStatusCode.Conflict);
        Assert.Equal(1, _spy.CallCount);
    }
}
