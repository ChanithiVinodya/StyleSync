using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using Testcontainers.PostgreSql;
using Xunit;

namespace StyleSync.Tests.Database;

public class PostgreSqlDatabaseFixture : IAsyncLifetime
{
    private readonly PostgreSqlContainer _container = new PostgreSqlBuilder("postgres:16-alpine")
        .WithDatabase("stylesync_test")
        .WithUsername("postgres")
        .WithPassword("postgres")
        .Build();

    public async Task InitializeAsync()
    {
        await _container.StartAsync();
        using var context = CreateContext();
        await context.Database.MigrateAsync();
    }

    public AppDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql(_container.GetConnectionString())
            .Options;

        return new AppDbContext(options);
    }

    public async Task DisposeAsync()
    {
        await _container.DisposeAsync();
    }
}
