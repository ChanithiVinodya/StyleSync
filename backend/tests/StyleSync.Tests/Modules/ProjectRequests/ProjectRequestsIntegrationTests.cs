using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Json;
using System.Security.Claims;
using System.Text.Encodings.Web;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectRequests.DTOs;
using StyleSync.Api.Modules.ProjectRequests.Models.Entities;
using StyleSync.Api.Modules.ProjectRequests.Models.Enums;
using Xunit;

namespace StyleSync.Tests.Modules.ProjectRequests;

public class TestAuthHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    public const string AuthenticationScheme = "TestScheme";

    public TestAuthHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder)
        : base(options, logger, encoder)
    {
    }

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Context.Request.Headers.ContainsKey("Authorization"))
        {
            return Task.FromResult(AuthenticateResult.Fail("No token"));
        }

        var header = Context.Request.Headers["Authorization"].ToString();
        var role = header.Replace("Bearer ", "");
        var userId = header.Contains("Client2") ? "22222222-2222-2222-2222-222222222222" : "11111111-1111-1111-1111-111111111111";

        var claims = new[] 
        { 
            new Claim(ClaimTypes.NameIdentifier, userId),
            new Claim(ClaimTypes.Role, role.Contains("Admin") ? "Admin" : "Client")
        };
        var identity = new ClaimsIdentity(claims, "Test");
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, AuthenticationScheme);

        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}

public class ProjectRequestsIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public ProjectRequestsIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureTestServices(services =>
            {
                var descriptor = services.SingleOrDefault(d => d.ServiceType == typeof(DbContextOptions<AppDbContext>));
                if (descriptor != null) services.Remove(descriptor);
                
                services.AddDbContext<AppDbContext>(options =>
                {
                    options.UseInMemoryDatabase("InMemoryDbForIntegrationTesting");
                });

                services.AddScoped<StyleSync.Api.Common.Storage.IFileStorage, StyleSync.Api.Common.Storage.FakeFileStorage>();

                services.AddAuthentication(TestAuthHandler.AuthenticationScheme)
                        .AddScheme<AuthenticationSchemeOptions, TestAuthHandler>(TestAuthHandler.AuthenticationScheme, options => { });

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

    private async Task<Guid> SeedRequest(Guid clientId, RequestStatus status)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var id = Guid.NewGuid();
        db.ProjectRequests.Add(new ProjectRequest
        {
            Id = id,
            ClientId = clientId,
            Status = status,
            ReferenceCode = "TEST-001"
        });
        await db.SaveChangesAsync();
        return id;
    }

    [Fact]
    public async Task Unauthenticated_Returns401()
    {
        var client = CreateClient("None");
        var res = await client.GetAsync($"/requests/{Guid.NewGuid()}");
        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    [Fact]
    public async Task ClientA_CannotReadEditDelete_ClientB_Request()
    {
        var clientB_Id = Guid.Parse("22222222-2222-2222-2222-222222222222");
        var reqId = await SeedRequest(clientB_Id, RequestStatus.Draft);

        var client = CreateClient("Client1");
        
        var getRes = await client.GetAsync($"/requests/{reqId}");
        Assert.Equal(HttpStatusCode.NotFound, getRes.StatusCode);

        var putRes = await client.PutAsJsonAsync($"/requests/{reqId}", new UpdateRequestDto(null, null, null, null, null));
        Assert.Equal(HttpStatusCode.NotFound, putRes.StatusCode);

        var delRes = await client.DeleteAsync($"/requests/{reqId}");
        Assert.Equal(HttpStatusCode.NotFound, delRes.StatusCode);
    }

    [Fact]
    public async Task Admin_CanReadAny_CannotCreateEditDelete()
    {
        var clientB_Id = Guid.Parse("22222222-2222-2222-2222-222222222222");
        var reqId = await SeedRequest(clientB_Id, RequestStatus.Draft);

        var adminClient = CreateClient("Admin");

        var getRes = await adminClient.GetAsync($"/requests/{reqId}");
        Assert.Equal(HttpStatusCode.OK, getRes.StatusCode);

        var postRes = await adminClient.PostAsJsonAsync("/requests", new CreateRequestDto(null, null, null, null, null));
        Assert.Equal(HttpStatusCode.Forbidden, postRes.StatusCode);

        var putRes = await adminClient.PutAsJsonAsync($"/requests/{reqId}", new UpdateRequestDto(null, null, null, null, null));
        Assert.Equal(HttpStatusCode.Forbidden, putRes.StatusCode);

        var delRes = await adminClient.DeleteAsync($"/requests/{reqId}");
        Assert.Equal(HttpStatusCode.Forbidden, delRes.StatusCode);
    }

    [Fact]
    public async Task ClientA_PutOrDelete_OnSubmitted_Returns409()
    {
        var clientA_Id = Guid.Parse("11111111-1111-1111-1111-111111111111");
        var reqId = await SeedRequest(clientA_Id, RequestStatus.Submitted);

        var client = CreateClient("Client1");

        var putRes = await client.PutAsJsonAsync($"/requests/{reqId}", new UpdateRequestDto(null, null, null, null, null));
        Assert.Equal(HttpStatusCode.Conflict, putRes.StatusCode);

        var delRes = await client.DeleteAsync($"/requests/{reqId}");
        Assert.Equal(HttpStatusCode.Conflict, delRes.StatusCode);
    }

    [Fact]
    public async Task ClientA_Post_BodySuppliedClientId_IsIgnored()
    {
        var clientA_Id = Guid.Parse("11111111-1111-1111-1111-111111111111");
        var client = CreateClient("Client1");

        var postRes = await client.PostAsJsonAsync("/requests", new { ClientId = Guid.NewGuid(), RoomType = "LivingRoom" });
        Assert.Equal(HttpStatusCode.Created, postRes.StatusCode);

        var options = new System.Text.Json.JsonSerializerOptions { PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase };
        options.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter());
        var content = await postRes.Content.ReadFromJsonAsync<RequestDetailDto>(options);
        Assert.Equal(clientA_Id, content!.ClientId);
    }
}
