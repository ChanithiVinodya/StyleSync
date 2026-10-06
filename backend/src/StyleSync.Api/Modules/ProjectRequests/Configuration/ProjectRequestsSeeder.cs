using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using StyleSync.Api.Common.Identity;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectRequests.Models.Entities;
using StyleSync.Api.Modules.ProjectRequests.Models.Enums;
using StyleSync.Api.Modules.ProjectRequests.Services;

namespace StyleSync.Api.Modules.ProjectRequests.Configuration;

public static class ProjectRequestsSeeder
{
    public static async Task SeedAsync(IServiceProvider serviceProvider)
    {
        using var scope = serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Idempotency check
        if (await context.ProjectRequests.AnyAsync()) return;

        // Ensure we have some clients
        var client1 = await context.Users.FirstOrDefaultAsync(u => u.Email == "client1@stylesync.com");
        if (client1 == null)
        {
            client1 = new AppUser
            {
                Id = Guid.NewGuid(),
                Email = "client1@stylesync.com",
                Name = "Alice Client",
                PasswordHash = "dummyhash",
                Role = UserRole.Client
            };
            context.Users.Add(client1);
        }

        var client2 = await context.Users.FirstOrDefaultAsync(u => u.Email == "client2@stylesync.com");
        if (client2 == null)
        {
            client2 = new AppUser
            {
                Id = Guid.NewGuid(),
                Email = "client2@stylesync.com",
                Name = "Bob Client",
                PasswordHash = "dummyhash",
                Role = UserRole.Client
            };
            context.Users.Add(client2);
        }

        await context.SaveChangesAsync();

        var random = new Random(42);
        var clients = new[] { client1.Id, client2.Id };
        var statuses = new[] { RequestStatus.Draft, RequestStatus.Submitted, RequestStatus.AIAnalysis, RequestStatus.ProposalReady, RequestStatus.Cancelled };
        var roomTypes = Enum.GetValues<RoomType>();
        
        var presetIds = PalettePresetCatalogue.All.Select(p => p.Id).ToList();

        for (int i = 1; i <= 12; i++)
        {
            var status = statuses[i % statuses.Length];
            var isFlagged = i == 6; // Just one flagged
            var clientId = clients[i % 2];
            var rt = roomTypes[i % roomTypes.Length];

            var req = new ProjectRequest
            {
                Id = Guid.NewGuid(),
                ReferenceCode = $"REQ-000{i:D3}",
                ClientId = clientId,
                RoomType = rt,
                RoomSizeSqFt = 100 + (i * 50),
                Budget = 10000 + (i * 1000), // MinBudget is 10000
                Description = $"A beautiful {rt} renovation project.",
                RequestedStyleTags = new() { "Modern Minimalist", "Scandinavian" },
                Status = status,
                CreatedAt = DateTime.UtcNow.AddDays(-i),
                UpdatedAt = DateTime.UtcNow.AddDays(-i).AddHours(1)
            };

            if (isFlagged)
            {
                req.IsFlagged = true;
                req.FlagReason = "Potentially unreasonable budget.";
                req.FlaggedAt = DateTime.UtcNow.AddDays(-i).AddHours(2);
            }

            if (status == RequestStatus.Cancelled)
            {
                req.CancelReason = "Client changed their mind.";
            }

            if (status != RequestStatus.Draft)
            {
                req.RoomPhotoUrl = $"https://stylesync.blob.core.windows.net/public/demo-room-{i}.jpg";
                req.RoomPhotoStorageKey = $"demo-room-{i}.jpg";
                req.SubmittedAt = req.UpdatedAt;

                req.StatusHistories.Add(new RequestStatusHistory
                {
                    ProjectRequestId = req.Id,
                    FromStatus = RequestStatus.Draft,
                    ToStatus = RequestStatus.Submitted,
                    ChangedAt = req.SubmittedAt.Value,
                    Note = "Submitted by client"
                });

                if (status != RequestStatus.Submitted)
                {
                    req.StatusHistories.Add(new RequestStatusHistory
                    {
                        ProjectRequestId = req.Id,
                        FromStatus = RequestStatus.Submitted,
                        ToStatus = status,
                        ChangedAt = req.SubmittedAt.Value.AddHours(1),
                        Note = $"Transitioned to {status}"
                    });
                }
            }

            // Add moodboards
            int mbCount = random.Next(0, 4);
            for (int m = 0; m < mbCount; m++)
            {
                req.MoodboardImages.Add(new MoodboardImage
                {
                    ProjectRequestId = req.Id,
                    Url = $"https://stylesync.blob.core.windows.net/public/demo-mood-{i}-{m}.jpg",
                    StorageKey = $"demo-mood-{i}-{m}.jpg",
                    SortOrder = m
                });
            }

            // Add Palette
            if (i % 2 == 0)
            {
                req.PaletteMode = "Preset";
                req.PalettePresetId = presetIds[random.Next(presetIds.Count)];
                var dto = new StyleSync.Api.Modules.ProjectRequests.DTOs.PaletteSelectionDto(req.PaletteMode, req.PalettePresetId, null);
                var resolved = PaletteService.Resolve(dto);
                foreach (var (hex, pos) in resolved)
                {
                    req.SuggestedPalettes.Add(new SuggestedPalette
                    {
                        ProjectRequestId = req.Id,
                        Hex = hex,
                        Position = pos,
                        Source = req.PaletteMode
                    });
                }
            }
            else
            {
                req.PaletteMode = "Generated";
                req.PaletteBaseHex = "#3498DB";
                var dto = new StyleSync.Api.Modules.ProjectRequests.DTOs.PaletteSelectionDto(req.PaletteMode, null, req.PaletteBaseHex);
                var resolved = PaletteService.Resolve(dto);
                foreach (var (hex, pos) in resolved)
                {
                    req.SuggestedPalettes.Add(new SuggestedPalette
                    {
                        ProjectRequestId = req.Id,
                        Hex = hex,
                        Position = pos,
                        Source = req.PaletteMode
                    });
                }
            }

            context.ProjectRequests.Add(req);
        }

        await context.SaveChangesAsync();
    }
}
