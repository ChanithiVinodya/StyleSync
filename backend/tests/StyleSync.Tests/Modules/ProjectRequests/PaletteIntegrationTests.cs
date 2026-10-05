using System;
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
using StyleSync.Api.Modules.ProjectRequests.DTOs;
using StyleSync.Api.Modules.ProjectRequests.Services;
using Xunit;
using Microsoft.EntityFrameworkCore;

namespace StyleSync.Tests.Modules.ProjectRequests;

public class PaletteIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public PaletteIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureTestServices(services =>
            {
                var descriptor = services.SingleOrDefault(d => d.ServiceType == typeof(DbContextOptions<AppDbContext>));
                if (descriptor != null) services.Remove(descriptor);
                
                services.AddDbContext<AppDbContext>(options =>
                {
                    options.UseInMemoryDatabase("InMemoryDbForPaletteIntegrationTesting");
                });

                services.AddScoped<StyleSync.Api.Common.Storage.IFileStorage, StyleSync.Api.Common.Storage.FakeFileStorage>();

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

    [Fact]
    public async Task GetPresets_Returns200_With10Presets()
    {
        var client = CreateClient("Client1");
        var res = await client.GetAsync("/palettes/presets");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);

        var presets = await res.Content.ReadFromJsonAsync<System.Collections.Generic.List<PresetPalette>>();
        Assert.NotNull(presets);
        Assert.Equal(10, presets.Count);
    }

    [Fact]
    public async Task GetGenerate_ValidHex_Returns200()
    {
        var client = CreateClient("Client1");
        var res = await client.GetAsync("/palettes/generate?baseColour=FF0000");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    [Fact]
    public async Task GetGenerate_Unauthenticated_Returns401()
    {
        var client = CreateClient("None");
        var res = await client.GetAsync("/palettes/generate?baseColour=FF0000");
        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }
}
