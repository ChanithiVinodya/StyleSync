using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Identity;

namespace StyleSync.Api.Common.Persistence;

public static class DbSeeder
{
    public static async Task SeedAdminUserAsync(IServiceProvider serviceProvider, IConfiguration configuration)
    {
        using var scope = serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var passwordHasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher<AppUser>>();

        // Apply pending migrations automatically on startup
        if (context.Database.IsNpgsql())
        {
            await context.Database.MigrateAsync();
        }

        // Check if an Admin already exists (idempotency)
        var adminExists = await context.Users.AnyAsync(u => u.Role == UserRole.Admin);
        if (!adminExists)
        {
            var adminEmail = Environment.GetEnvironmentVariable("STYLESYNC_ADMIN_EMAIL")
                             ?? configuration["AdminSeed:Email"]
                             ?? "admin@stylesync.com";

            var adminPassword = Environment.GetEnvironmentVariable("STYLESYNC_ADMIN_PASSWORD")
                                ?? configuration["AdminSeed:Password"]
                                ?? "Admin@StyleSync2026!";

            var adminUser = new AppUser
            {
                Id = Guid.NewGuid(),
                Name = "System Administrator",
                Email = adminEmail.Trim().ToLowerInvariant(),
                Role = UserRole.Admin,
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            adminUser.PasswordHash = passwordHasher.HashPassword(adminUser, adminPassword);

            context.Users.Add(adminUser);
            await context.SaveChangesAsync();
        }
    }
}
