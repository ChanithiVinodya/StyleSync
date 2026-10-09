using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Identity;
using StyleSync.Api.Models;
using StyleSync.Api.Modules.Designers.Models;
using StyleSync.Api.Modules.ProjectRequests.Models.Entities;
using StyleSync.Api.Modules.ProjectRequests.Models.Enums;
using Xunit;

namespace StyleSync.Tests.Database;

public class DatabaseIntegrationTests : IClassFixture<PostgreSqlDatabaseFixture>
{
    private readonly PostgreSqlDatabaseFixture _fixture;

    public DatabaseIntegrationTests(PostgreSqlDatabaseFixture fixture)
    {
        _fixture = fixture;
    }

    [Fact]
    [Trait("TestCase", "TC-DB-01")]
    public async Task Migrations_ApplyToEmptyDatabase_SuccessfullyCreatesSchema()
    {
        await using var context = _fixture.CreateContext();

        var canConnect = await context.Database.CanConnectAsync();
        Assert.True(canConnect, "Database connection should succeed after migrations.");

        var appliedMigrations = await context.Database.GetAppliedMigrationsAsync();
        Assert.NotEmpty(appliedMigrations);
    }

    [Fact]
    [Trait("TestCase", "TC-DB-02")]
    public async Task DesignerProfiles_TwoProfilesForSameUser_ThrowsDbUpdateException()
    {
        var user = new AppUser
        {
            Id = Guid.NewGuid(),
            Name = "Designer Single User",
            Email = $"designer_unique_{Guid.NewGuid()}@stylesync.local",
            PasswordHash = "hash123",
            Role = UserRole.Designer
        };

        await using (var context1 = _fixture.CreateContext())
        {
            context1.Users.Add(user);
            await context1.SaveChangesAsync();

            var profile1 = new DesignerProfile
            {
                UserId = user.Id,
                DisplayName = "First Studio",
                Bio = "Bio One",
                PriceRangeMin = 100000m,
                PriceRangeMax = 300000m,
                RatePerSqFt = 500m,
                ListingStatus = ListingStatus.Published
            };
            context1.DesignerProfiles.Add(profile1);
            await context1.SaveChangesAsync();
        }

        // In a subsequent context, attempt to add a second designer profile for the same user
        await using (var context2 = _fixture.CreateContext())
        {
            var profile2 = new DesignerProfile
            {
                UserId = user.Id,
                DisplayName = "Second Studio",
                Bio = "Bio Two",
                PriceRangeMin = 150000m,
                PriceRangeMax = 350000m,
                RatePerSqFt = 600m,
                ListingStatus = ListingStatus.Draft
            };
            context2.DesignerProfiles.Add(profile2);

            // Assert: 1-to-1 relationship on UserId enforces unique constraint in PostgreSQL, throwing DbUpdateException
            await Assert.ThrowsAsync<DbUpdateException>(() => context2.SaveChangesAsync());
        }
    }

    [Fact]
    [Trait("TestCase", "TC-DB-03")]
    public async Task PortfolioItems_MissingDesignerForeignKey_ThrowsDbUpdateException()
    {
        await using var context = _fixture.CreateContext();

        var invalidItem = new PortfolioItem
        {
            DesignerProfileId = 999999, // Non-existent DesignerProfileId
            Title = "Orphan Portfolio Project",
            Description = "Description without designer",
            ImageUrl = "https://example.com/orphan.jpg",
            BudgetRangeLabel = "100k - 200k",
            ClientInitials = "XX",
            CompletionStatusBadge = ListingStatus.Published
        };

        context.PortfolioItems.Add(invalidItem);

        // Assert: Foreign key constraint violation on DesignerProfileId
        await Assert.ThrowsAsync<DbUpdateException>(() => context.SaveChangesAsync());
    }

    [Fact]
    [Trait("TestCase", "TC-DB-04")]
    public async Task ProjectRequests_WithoutValidClientId_ThrowsDbUpdateException()
    {
        await using var context = _fixture.CreateContext();

        var orphanRequest = new ProjectRequest
        {
            Id = Guid.NewGuid(),
            ClientId = Guid.NewGuid(), // Non-existent ClientId (foreign key not in Users)
            ReferenceCode = $"REQ-{Guid.NewGuid().ToString()[..6].ToUpper()}",
            RoomType = RoomType.LivingRoom,
            RoomSizeSqFt = 400m,
            Budget = 200000m,
            Description = "Request with invalid client reference",
            Status = RequestStatus.Draft
        };

        context.ProjectRequests.Add(orphanRequest);

        // Assert: Foreign key constraint violation on ClientId
        await Assert.ThrowsAsync<DbUpdateException>(() => context.SaveChangesAsync());
    }

    [Fact]
    [Trait("TestCase", "TC-DB-05")]
    public async Task Users_DuplicateEmail_ThrowsDbUpdateException()
    {
        await using var context = _fixture.CreateContext();

        var duplicateEmail = $"shared_{Guid.NewGuid()}@stylesync.local";

        var user1 = new AppUser
        {
            Id = Guid.NewGuid(),
            Name = "Primary User",
            Email = duplicateEmail,
            PasswordHash = "hash1",
            Role = UserRole.Client
        };
        context.Users.Add(user1);
        await context.SaveChangesAsync();

        var user2 = new AppUser
        {
            Id = Guid.NewGuid(),
            Name = "Secondary User",
            Email = duplicateEmail, // Same email
            PasswordHash = "hash2",
            Role = UserRole.Designer
        };
        context.Users.Add(user2);

        // Assert: Unique index on Users.Email triggers DbUpdateException
        await Assert.ThrowsAsync<DbUpdateException>(() => context.SaveChangesAsync());
    }

    [Fact]
    [Trait("TestCase", "TC-DB-06")]
    public async Task Decimals_SaveAndReadBackInNewContext_ExactMatch()
    {
        var clientId = Guid.NewGuid();
        var requestId = Guid.NewGuid();
        const decimal expectedDecimal = 1234567.89m;

        await using (var context1 = _fixture.CreateContext())
        {
            var client = new AppUser
            {
                Id = clientId,
                Name = "Decimal Client",
                Email = $"decimal_{Guid.NewGuid()}@stylesync.local",
                PasswordHash = "hash",
                Role = UserRole.Client
            };
            context1.Users.Add(client);

            var request = new ProjectRequest
            {
                Id = requestId,
                ClientId = clientId,
                ReferenceCode = "REQ-DEC-01",
                RoomType = RoomType.LivingRoom,
                RoomSizeSqFt = 1500.50m,
                Budget = expectedDecimal,
                Description = "Decimal precision test",
                Status = RequestStatus.Draft
            };
            context1.ProjectRequests.Add(request);

            await context1.SaveChangesAsync();
        }

        await using (var context2 = _fixture.CreateContext())
        {
            var reloaded = await context2.ProjectRequests.AsNoTracking().FirstOrDefaultAsync(r => r.Id == requestId);

            Assert.NotNull(reloaded);
            Assert.Equal(expectedDecimal, reloaded.Budget);
        }
    }

    [Fact]
    [Trait("TestCase", "TC-DB-07")]
    public async Task DesignerProfile_DeleteWithPortfolioItems_CascadesDeletion()
    {
        int designerId;
        int portfolioItemId1;
        int portfolioItemId2;

        await using (var setupContext = _fixture.CreateContext())
        {
            var user = new AppUser
            {
                Id = Guid.NewGuid(),
                Name = "Cascade Designer",
                Email = $"cascade_{Guid.NewGuid()}@stylesync.local",
                PasswordHash = "hash",
                Role = UserRole.Designer
            };
            setupContext.Users.Add(user);
            await setupContext.SaveChangesAsync();

            var designer = new DesignerProfile
            {
                UserId = user.Id,
                DisplayName = "Cascade Studio",
                Bio = "Studio to be deleted",
                PriceRangeMin = 100000m,
                PriceRangeMax = 300000m,
                RatePerSqFt = 450m
            };
            setupContext.DesignerProfiles.Add(designer);
            await setupContext.SaveChangesAsync();

            designerId = designer.Id;

            var item1 = new PortfolioItem
            {
                DesignerProfileId = designerId,
                Title = "Portfolio One",
                Description = "Description One",
                ImageUrl = "https://example.com/one.jpg",
                BudgetRangeLabel = "100k",
                ClientInitials = "AA",
                CompletionStatusBadge = ListingStatus.Published
            };
            var item2 = new PortfolioItem
            {
                DesignerProfileId = designerId,
                Title = "Portfolio Two",
                Description = "Description Two",
                ImageUrl = "https://example.com/two.jpg",
                BudgetRangeLabel = "200k",
                ClientInitials = "BB",
                CompletionStatusBadge = ListingStatus.Published
            };
            setupContext.PortfolioItems.AddRange(item1, item2);
            await setupContext.SaveChangesAsync();

            portfolioItemId1 = item1.Id;
            portfolioItemId2 = item2.Id;
        }

        // Action: Delete the designer profile in a new context
        await using (var deleteContext = _fixture.CreateContext())
        {
            var profileToDelete = await deleteContext.DesignerProfiles.FindAsync(designerId);
            Assert.NotNull(profileToDelete);

            deleteContext.DesignerProfiles.Remove(profileToDelete);
            await deleteContext.SaveChangesAsync();
        }

        // Assert: Configured delete rule is DeleteBehavior.Cascade
        await using (var verifyContext = _fixture.CreateContext())
        {
            var profileExists = await verifyContext.DesignerProfiles.AnyAsync(d => d.Id == designerId);
            Assert.False(profileExists, "Designer profile should be deleted.");

            var remainingItems = await verifyContext.PortfolioItems
                .Where(p => p.Id == portfolioItemId1 || p.Id == portfolioItemId2)
                .ToListAsync();

            Assert.Empty(remainingItems);
        }
    }

    [Fact]
    [Trait("TestCase", "TC-DB-08")]
    public async Task Transaction_ValidInsertFollowedByInvalidInsert_RollsBackEntirely()
    {
        var validUserId = Guid.NewGuid();

        await using var context = _fixture.CreateContext();
        await using var transaction = await context.Database.BeginTransactionAsync();

        try
        {
            // 1. Valid insert
            var validUser = new AppUser
            {
                Id = validUserId,
                Name = "Rollback Candidate",
                Email = $"rollback_{Guid.NewGuid()}@stylesync.local",
                PasswordHash = "hash",
                Role = UserRole.Client
            };
            context.Users.Add(validUser);
            await context.SaveChangesAsync();

            // 2. Invalid insert: PortfolioItem with non-existent foreign key (999999)
            var invalidItem = new PortfolioItem
            {
                DesignerProfileId = 999999,
                Title = "Fail Portfolio",
                Description = "Will fail FK",
                ImageUrl = "https://example.com/fail.jpg",
                BudgetRangeLabel = "100k",
                ClientInitials = "FF",
                CompletionStatusBadge = ListingStatus.Published
            };
            context.PortfolioItems.Add(invalidItem);
            await context.SaveChangesAsync();

            await transaction.CommitAsync();
            Assert.Fail("Transaction should have failed on invalid foreign key insert.");
        }
        catch (DbUpdateException)
        {
            await transaction.RollbackAsync();
        }

        // Verify in fresh context that the valid user was rolled back
        await using var verifyContext = _fixture.CreateContext();
        var userPersisted = await verifyContext.Users.AnyAsync(u => u.Id == validUserId);
        Assert.False(userPersisted, "Valid user insert within failed transaction must be rolled back completely.");
    }

    [Theory]
    [Trait("TestCase", "TC-DB-09")]
    [InlineData(RequestStatus.Draft)]
    [InlineData(RequestStatus.Submitted)]
    [InlineData(RequestStatus.AIAnalysis)]
    [InlineData(RequestStatus.ProposalReady)]
    [InlineData(RequestStatus.AwaitingApproval)]
    [InlineData(RequestStatus.Approved)]
    [InlineData(RequestStatus.DesignerAssigned)]
    [InlineData(RequestStatus.InProgress)]
    [InlineData(RequestStatus.Completed)]
    [InlineData(RequestStatus.Rejected)]
    [InlineData(RequestStatus.Cancelled)]
    public async Task ProjectRequest_AllRequestStatusValues_RoundTripUnchanged(RequestStatus expectedStatus)
    {
        var requestId = Guid.NewGuid();
        var clientId = Guid.NewGuid();

        await using (var context1 = _fixture.CreateContext())
        {
            var client = new AppUser
            {
                Id = clientId,
                Name = $"Status Client {expectedStatus}",
                Email = $"status_{Guid.NewGuid()}@stylesync.local",
                PasswordHash = "hash",
                Role = UserRole.Client
            };
            context1.Users.Add(client);

            var request = new ProjectRequest
            {
                Id = requestId,
                ClientId = clientId,
                ReferenceCode = $"REQ-{expectedStatus}-{Guid.NewGuid().ToString()[..4]}",
                RoomType = RoomType.Office,
                RoomSizeSqFt = 250m,
                Budget = 500000m,
                Description = $"Testing status {expectedStatus}",
                Status = expectedStatus
            };
            context1.ProjectRequests.Add(request);

            await context1.SaveChangesAsync();
        }

        await using (var context2 = _fixture.CreateContext())
        {
            var reloaded = await context2.ProjectRequests.AsNoTracking().FirstOrDefaultAsync(r => r.Id == requestId);

            Assert.NotNull(reloaded);
            Assert.Equal(expectedStatus, reloaded.Status);
        }
    }
}
