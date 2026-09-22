using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Identity;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.Designers.Controllers;
using StyleSync.Api.Modules.Designers.DTOs;
using StyleSync.Api.Modules.Designers.Models;
using StyleSync.Api.Modules.Designers.Services;
using System.Security.Claims;
using Xunit;

namespace StyleSync.Tests.Modules.Designers;

public class DesignerCrudTests
{
    private AppDbContext CreateInMemoryDbContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        return new AppDbContext(options);
    }

    private DesignerService CreateDesignerService(AppDbContext context)
    {
        var guard = new CapacityGuardService(context);
        return new DesignerService(context, guard);
    }

    private static ClaimsPrincipal CreateClaimsPrincipal(int userId, string role)
    {
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, userId.ToString()),
            new(ClaimTypes.Role, role)
        };
        var identity = new ClaimsIdentity(claims, "TestAuth");
        return new ClaimsPrincipal(identity);
    }

    [Fact]
    public async Task CreateProfile_ValidRequest_CreatesProfileAsDraft()
    {
        using var context = CreateInMemoryDbContext();
        var service = CreateDesignerService(context);

        var request = new CreateDesignerProfileRequest
        {
            DisplayName = "Test Studio",
            Bio = "Creating modern interiors",
            StyleTags = new() { "Minimalist", "Modern" },
            ServiceCategories = new() { "Living Room" },
            PriceRangeMin = 100000m,
            PriceRangeMax = 300000m,
            RatePerSqFt = 350m,
            IsAvailable = true
        };

        var response = await service.CreateProfileAsync(currentUserId: 10, isAdmin: false, request);

        Assert.NotNull(response);
        Assert.Equal("Test Studio", response.DisplayName);
        Assert.Equal(ListingStatus.Draft, response.ListingStatus);
        Assert.Equal(3, response.MaxConcurrentProjects); // default 3
    }

    [Fact]
    public async Task CreateProfile_PriceMinGreaterThanPriceMax_ThrowsArgumentException()
    {
        using var context = CreateInMemoryDbContext();
        var service = CreateDesignerService(context);

        var request = new CreateDesignerProfileRequest
        {
            DisplayName = "Invalid Price Studio",
            Bio = "Bio",
            PriceRangeMin = 500000m,
            PriceRangeMax = 200000m // Min > Max
        };

        await Assert.ThrowsAsync<ArgumentException>(() =>
            service.CreateProfileAsync(currentUserId: 11, isAdmin: false, request));
    }

    [Fact]
    public async Task UpdateProfile_DesignerEditsOwnProfile_Succeeds()
    {
        using var context = CreateInMemoryDbContext();
        var service = CreateDesignerService(context);

        var profile = new DesignerProfile
        {
            UserId = 10,
            DisplayName = "Original Name",
            Bio = "Original Bio",
            PriceRangeMin = 100000m,
            PriceRangeMax = 200000m,
            RatePerSqFt = 300m,
            MaxConcurrentProjects = 3,
            ListingStatus = ListingStatus.Draft
        };
        context.DesignerProfiles.Add(profile);
        await context.SaveChangesAsync();

        var updateRequest = new UpdateDesignerProfileRequest
        {
            DisplayName = "Updated Studio Name",
            Bio = "Updated Bio",
            PriceRangeMin = 120000m,
            PriceRangeMax = 250000m,
            RatePerSqFt = 400m,
            IsAvailable = true,
            ListingStatus = ListingStatus.Published
        };

        var updated = await service.UpdateProfileAsync(profile.Id, currentUserId: 10, isAdmin: false, updateRequest);

        Assert.Equal("Updated Studio Name", updated.DisplayName);
        Assert.Equal(ListingStatus.Published, updated.ListingStatus);
    }

    [Fact]
    public async Task UpdateProfile_DesignerEditsOtherProfile_ThrowsUnauthorizedAccessException()
    {
        using var context = CreateInMemoryDbContext();
        var service = CreateDesignerService(context);

        var profile = new DesignerProfile
        {
            UserId = 10,
            DisplayName = "Designer 10's Profile",
            Bio = "Bio",
            PriceRangeMin = 100000m,
            PriceRangeMax = 200000m,
            RatePerSqFt = 300m
        };
        context.DesignerProfiles.Add(profile);
        await context.SaveChangesAsync();

        var updateRequest = new UpdateDesignerProfileRequest
        {
            DisplayName = "Hacked Name",
            Bio = "Bio",
            PriceRangeMin = 100000m,
            PriceRangeMax = 200000m
        };

        // User 20 attempts to update user 10's profile
        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            service.UpdateProfileAsync(profile.Id, currentUserId: 20, isAdmin: false, updateRequest));
    }

    [Fact]
    public async Task UpdateProfile_AdminOverridesCapacityAndStatus_Succeeds()
    {
        using var context = CreateInMemoryDbContext();
        var service = CreateDesignerService(context);

        var profile = new DesignerProfile
        {
            UserId = 10,
            DisplayName = "Designer Profile",
            Bio = "Bio",
            PriceRangeMin = 100000m,
            PriceRangeMax = 200000m,
            RatePerSqFt = 300m,
            MaxConcurrentProjects = 3,
            ListingStatus = ListingStatus.Published
        };
        context.DesignerProfiles.Add(profile);
        await context.SaveChangesAsync();

        var updateRequest = new UpdateDesignerProfileRequest
        {
            DisplayName = "Designer Profile",
            Bio = "Bio",
            PriceRangeMin = 100000m,
            PriceRangeMax = 200000m,
            RatePerSqFt = 300m,
            MaxConcurrentProjects = 5, // Admin overrides max projects
            ListingStatus = ListingStatus.Suspended // Admin sets Suspended
        };

        var updated = await service.UpdateProfileAsync(profile.Id, currentUserId: 99, isAdmin: true, updateRequest);

        Assert.Equal(5, updated.MaxConcurrentProjects);
        Assert.Equal(ListingStatus.Suspended, updated.ListingStatus);
    }

    [Fact]
    public async Task ArchiveProfile_AdminSoftDeletes_SetsStatusToArchived()
    {
        using var context = CreateInMemoryDbContext();
        var service = CreateDesignerService(context);

        var profile = new DesignerProfile
        {
            UserId = 10,
            DisplayName = "To Be Archived",
            Bio = "Bio",
            ListingStatus = ListingStatus.Published
        };
        context.DesignerProfiles.Add(profile);
        await context.SaveChangesAsync();

        var result = await service.ArchiveProfileAsync(profile.Id, isAdmin: true);

        Assert.True(result);
        var inDb = await context.DesignerProfiles.FindAsync(profile.Id);
        Assert.NotNull(inDb); // Not hard deleted
        Assert.Equal(ListingStatus.Archived, inDb.ListingStatus);
    }

    [Fact]
    public async Task PortfolioCRUD_AddAndRemoveItems_EnforcesOwnership()
    {
        using var context = CreateInMemoryDbContext();
        var service = CreateDesignerService(context);

        var profile = new DesignerProfile
        {
            UserId = 10,
            DisplayName = "Designer Studio",
            Bio = "Bio"
        };
        context.DesignerProfiles.Add(profile);
        await context.SaveChangesAsync();

        var itemRequest = new CreatePortfolioItemRequest
        {
            Title = "Modern Villa Living Room",
            Description = "Teak furnishings and diffused light",
            ImageUrl = "https://example.com/item1.jpg",
            BudgetRangeLabel = "LKR 200k-300k",
            ClientInitials = "A.B."
        };

        // Add item as owner
        var createdItem = await service.AddPortfolioItemAsync(profile.Id, currentUserId: 10, isAdmin: false, itemRequest);
        Assert.NotNull(createdItem);
        Assert.Equal("Modern Villa Living Room", createdItem.Title);

        // Another user cannot delete it
        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            service.DeletePortfolioItemAsync(profile.Id, createdItem.Id, currentUserId: 20, isAdmin: false));

        // Owner deletes it
        var deleted = await service.DeletePortfolioItemAsync(profile.Id, createdItem.Id, currentUserId: 10, isAdmin: false);
        Assert.True(deleted);

        var items = await service.GetPortfolioItemsAsync(profile.Id, publicOnly: false);
        Assert.Empty(items);
    }
}
