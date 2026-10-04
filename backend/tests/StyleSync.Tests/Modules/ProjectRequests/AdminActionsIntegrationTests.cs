using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.TestHost;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectRequests.Models.Entities;
using StyleSync.Api.Modules.ProjectRequests.Models.Enums;
using StyleSync.Api.Common.Identity;
using StyleSync.Api.Modules.ProjectRequests.DTOs;
using Xunit;
using Microsoft.EntityFrameworkCore;

namespace StyleSync.Tests.Modules.ProjectRequests;

public class AdminActionsIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public AdminActionsIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureTestServices(services =>
            {
                var descriptor = services.SingleOrDefault(d => d.ServiceType == typeof(DbContextOptions<AppDbContext>));
                if (descriptor != null) services.Remove(descriptor);
                
                var dbName = "InMemoryDbForAdminActions" + Guid.NewGuid().ToString();
                services.AddDbContext<AppDbContext>(options =>
                {
                    options.UseInMemoryDatabase(dbName);
                });

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

    private HttpClient CreateClient(string roleAndIdentifier = "Admin")
    {
        var client = _factory.CreateClient(new WebApplicationFactoryClientOptions { AllowAutoRedirect = false });
        if (roleAndIdentifier != "None")
        {
            client.DefaultRequestHeaders.Add("Authorization", $"Bearer {roleAndIdentifier}");
        }
        return client;
    }

    private async Task<Guid> SeedRequest(RequestStatus status = RequestStatus.Draft, decimal budget = 1000m, RoomType roomType = RoomType.LivingRoom, bool isFlagged = false)
    {
        Guid reqId = Guid.NewGuid();
        Guid clientId = Guid.Parse("11111111-1111-1111-1111-111111111111");
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
            RoomSizeSqFt = 200,
            RoomType = roomType,
            Description = "desc",
            IsFlagged = isFlagged,
            FlagReason = isFlagged ? "bad" : null,
            CreatedAt = DateTime.UtcNow
        });
        await db.SaveChangesAsync();
        return reqId;
    }

    [Fact]
    public async Task Cancel_EmptyReason_Returns400()
    {
        var reqId = await SeedRequest(RequestStatus.Draft);
        var client = CreateClient("Admin");
        var res = await client.PostAsJsonAsync($"/requests/{reqId}/cancel", new CancelRequestDto(""));
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
    }

    [Fact]
    public async Task Cancel_Completed_Returns409()
    {
        var reqId = await SeedRequest(RequestStatus.Completed);
        var client = CreateClient("Admin");
        var res = await client.PostAsJsonAsync($"/requests/{reqId}/cancel", new CancelRequestDto("Cancel please"));
        Assert.Equal(HttpStatusCode.Conflict, res.StatusCode);
    }

    [Fact]
    public async Task Cancel_Valid_Returns200_AndWritesAudit()
    {
        var reqId = await SeedRequest(RequestStatus.Submitted);
        var client = CreateClient("Admin");
        var res = await client.PostAsJsonAsync($"/requests/{reqId}/cancel", new CancelRequestDto("Reasonable Cancel"));
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var req = await db.ProjectRequests.FirstAsync(r => r.Id == reqId);
        Assert.Equal(RequestStatus.Cancelled, req.Status);
        Assert.Equal("Reasonable Cancel", req.CancelReason);
        
        var audit = await db.RequestAuditLogs.FirstAsync(a => a.EntityId == reqId);
        Assert.Equal("REQUEST_CANCELLED", audit.Action);
        Assert.Equal("Reasonable Cancel", audit.Reason);
    }

    [Fact]
    public async Task Flag_Valid_Returns200_DoesNotChangeStatus()
    {
        var reqId = await SeedRequest(RequestStatus.Draft);
        var client = CreateClient("Admin");
        var res = await client.PostAsJsonAsync($"/requests/{reqId}/flag", new FlagRequestDto("Inappropriate content", true));
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var req = await db.ProjectRequests.FirstAsync(r => r.Id == reqId);
        Assert.True(req.IsFlagged);
        Assert.Equal("Inappropriate content", req.FlagReason);
        Assert.Equal(RequestStatus.Draft, req.Status); // status unchanged

        var audit = await db.RequestAuditLogs.FirstAsync(a => a.EntityId == reqId);
        Assert.Equal("REQUEST_FLAGGED", audit.Action);
    }

    [Fact]
    public async Task ClientRole_Gets403()
    {
        var reqId = await SeedRequest();
        var client = CreateClient("Client1");
        Assert.Equal(HttpStatusCode.Forbidden, (await client.PostAsJsonAsync($"/requests/{reqId}/cancel", new CancelRequestDto("Cancel please"))).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await client.PostAsJsonAsync($"/requests/{reqId}/flag", new FlagRequestDto("flag", true))).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await client.GetAsync("/requests/analytics")).StatusCode);
    }

    [Fact]
    public async Task Analytics_Empty_ReturnsZeros()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        db.ProjectRequests.RemoveRange(db.ProjectRequests);
        await db.SaveChangesAsync();

        var client = CreateClient("Admin");
        var res = await client.GetAsync("/requests/analytics");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);

        var data = await res.Content.ReadFromJsonAsync<AnalyticsResponseDto>();
        Assert.NotNull(data);
        Assert.Equal(0, data.TotalRequests);
        Assert.Null(data.AverageBudget);
        Assert.Contains(data.ByStatus, s => s.Status == "Draft" && s.Count == 0);
    }

    [Fact]
    public async Task Analytics_WithSeed_MatchesExpectations()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        db.ProjectRequests.RemoveRange(db.ProjectRequests);
        await db.SaveChangesAsync();

        await SeedRequest(RequestStatus.Draft, 1000m, RoomType.LivingRoom, false);
        await SeedRequest(RequestStatus.Submitted, 2000m, RoomType.Kitchen, true);
        await SeedRequest(RequestStatus.Completed, 3000m, RoomType.Bedroom, false);
        await SeedRequest(RequestStatus.Cancelled, 9000m, RoomType.Bathroom, false); // Cancelled budget ignored
        await SeedRequest(RequestStatus.AIAnalysis, 2500m, RoomType.LivingRoom, false);
        await SeedRequest(RequestStatus.Draft, 1500m, RoomType.Kitchen, false);
        
        var client = CreateClient("Admin");
        var res = await client.GetAsync("/requests/analytics");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
        
        var data = await res.Content.ReadFromJsonAsync<AnalyticsResponseDto>();
        Assert.NotNull(data);
        Assert.Equal(6, data.TotalRequests);
        Assert.Equal(1, data.FlaggedCount);
        
        // Average budget = (1000 + 2000 + 3000 + 2500 + 1500) / 5 = 10000 / 5 = 2000
        Assert.Equal(2000m, data.AverageBudget);
        
        var draftCount = data.ByStatus.First(s => s.Status == "Draft").Count;
        Assert.Equal(2, draftCount);

        var livingRoomBudget = data.AverageBudgetByRoomType.First(rt => rt.RoomType == "LivingRoom").AverageBudget;
        Assert.Equal(1750m, livingRoomBudget); // 1000 + 2500 / 2 = 1750
    }
}
