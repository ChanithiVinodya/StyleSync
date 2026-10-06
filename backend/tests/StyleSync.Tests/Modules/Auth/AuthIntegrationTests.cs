using System;
using System.Linq;
using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.DTOs;
using Xunit;

namespace StyleSync.Tests.Modules.Auth;

public class AuthIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public AuthIntegrationTests(WebApplicationFactory<Program> factory)
    {
        var databaseName = $"AuthIntegrationDb_{Guid.NewGuid()}";

        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                var descriptor = services.SingleOrDefault(
                    d => d.ServiceType == typeof(DbContextOptions<AppDbContext>));

                if (descriptor != null)
                {
                    services.Remove(descriptor);
                }

                services.AddDbContext<AppDbContext>(options =>
                {
                    options.UseInMemoryDatabase(databaseName);
                });
            });
        });
    }

    [Fact]
    public async Task TC_API_01_RegisterAndLogin_ReturnsJwt()
    {
        var client = _factory.CreateClient();

        var email = $"client_{Guid.NewGuid()}@stylesync.test";
        var password = "Password123!";

        var registerRequest = new RegisterRequest
        {
            Name = "Test Client",
            Email = email,
            Password = password,
            ConfirmPassword = password
        };

        var registerResponse =
            await client.PostAsJsonAsync(
                "/api/auth/register",
                registerRequest);

        Assert.Equal(
            HttpStatusCode.Created,
            registerResponse.StatusCode);

        var loginRequest = new LoginRequest
        {
            Email = email,
            Password = password
        };

        var loginResponse =
            await client.PostAsJsonAsync(
                "/api/auth/login",
                loginRequest);

        Assert.Equal(
            HttpStatusCode.OK,
            loginResponse.StatusCode);

        var loginData =
            await loginResponse.Content.ReadFromJsonAsync<LoginResponse>();

        Assert.NotNull(loginData);

        Assert.False(
            string.IsNullOrWhiteSpace(loginData!.Token));
    }

    [Fact]
    public async Task TC_API_02_WrongPassword_Returns401()
    {
        var client = _factory.CreateClient();

        var email = $"client_{Guid.NewGuid()}@stylesync.test";
        var correctPassword = "Password123!";

        var registerRequest = new RegisterRequest
        {
            Name = "Test Client",
            Email = email,
            Password = correctPassword,
            ConfirmPassword = correctPassword
        };

        var registerResponse =
            await client.PostAsJsonAsync(
                "/api/auth/register",
                registerRequest);

        Assert.Equal(
            HttpStatusCode.Created,
            registerResponse.StatusCode);

        var loginRequest = new LoginRequest
        {
            Email = email,
            Password = "WrongPassword123!"
        };

        var loginResponse =
            await client.PostAsJsonAsync(
                "/api/auth/login",
                loginRequest);

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            loginResponse.StatusCode);
    }

    [Fact]
    public async Task TC_API_03_DuplicateEmail_Returns409()
    {
        var client = _factory.CreateClient();

        var email = $"duplicate_{Guid.NewGuid()}@stylesync.test";
        var password = "Password123!";

        var registerRequest = new RegisterRequest
        {
            Name = "Test Client",
            Email = email,
            Password = password,
            ConfirmPassword = password
        };

        var firstResponse =
            await client.PostAsJsonAsync(
                "/api/auth/register",
                registerRequest);

        Assert.Equal(
            HttpStatusCode.Created,
            firstResponse.StatusCode);

        var secondResponse =
            await client.PostAsJsonAsync(
                "/api/auth/register",
                registerRequest);

        Assert.Equal(
            HttpStatusCode.Conflict,
            secondResponse.StatusCode);
    }
}