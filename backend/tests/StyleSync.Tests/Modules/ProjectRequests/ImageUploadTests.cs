using System;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectRequests.Models.Entities;
using StyleSync.Api.Modules.ProjectRequests.Models.Enums;
using Xunit;
using Microsoft.AspNetCore.TestHost;

namespace StyleSync.Tests.Modules.ProjectRequests;

public class ImageUploadTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public ImageUploadTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureTestServices(services =>
            {
                var descriptor = services.SingleOrDefault(d => d.ServiceType == typeof(DbContextOptions<AppDbContext>));
                if (descriptor != null) services.Remove(descriptor);
                
                services.AddDbContext<AppDbContext>(options =>
                {
                    options.UseInMemoryDatabase("InMemoryDbForImageTesting");
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
    public async Task Upload_InvalidSignature_Returns400()
    {
        var clientA_Id = Guid.Parse("11111111-1111-1111-1111-111111111111");
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var id = Guid.NewGuid();
        db.ProjectRequests.Add(new ProjectRequest { Id = id, ClientId = clientA_Id, Status = RequestStatus.Draft });
        await db.SaveChangesAsync();

        var client = CreateClient("Client1");

        using var content = new MultipartFormDataContent();
        content.Add(new StringContent("room"), "type");

        var fileContent = new ByteArrayContent(new byte[] { 0x01, 0x02, 0x03, 0x04 }); // Not a JPEG/PNG
        fileContent.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
        content.Add(fileContent, "files", "fake.jpg");

        var res = await client.PostAsync($"/requests/{id}/images", content);
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
    }
}
