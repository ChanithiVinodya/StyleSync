using Microsoft.EntityFrameworkCore;
using StyleSync.Backend.Domain.Entities;
using System.Text.Json;

namespace StyleSync.Backend.Data;

public class StyleSyncDbContext : DbContext
{
    public StyleSyncDbContext(DbContextOptions<StyleSyncDbContext> options) : base(options)
    {
    }

    public DbSet<ProjectRequest> ProjectRequests => Set<ProjectRequest>();
    public DbSet<ProjectRequestPhoto> ProjectRequestPhotos => Set<ProjectRequestPhoto>();
    public DbSet<StyleAnalysisResult> StyleAnalysisResults => Set<StyleAnalysisResult>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<ProjectRequest>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.RoomType).IsRequired().HasMaxLength(100);
            entity.Property(e => e.BudgetLkr).HasPrecision(18, 2);
            entity.Property(e => e.PreferredStyles)
                .HasConversion(
                    v => JsonSerializer.Serialize(v, (JsonSerializerOptions?)null),
                    v => JsonSerializer.Deserialize<List<string>>(v, (JsonSerializerOptions?)null) ?? new List<string>()
                );
            entity.HasQueryFilter(e => !e.IsDeleted);

            entity.HasMany(e => e.Photos)
                .WithOne()
                .HasForeignKey(p => p.ProjectRequestId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.StyleAnalysis)
                .WithOne()
                .HasForeignKey<StyleAnalysisResult>(s => s.ProjectRequestId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<StyleAnalysisResult>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.RecommendedColors)
                .HasConversion(
                    v => JsonSerializer.Serialize(v, (JsonSerializerOptions?)null),
                    v => JsonSerializer.Deserialize<List<string>>(v, (JsonSerializerOptions?)null) ?? new List<string>()
                );
            entity.Property(e => e.DetectedFeatures)
                .HasConversion(
                    v => JsonSerializer.Serialize(v, (JsonSerializerOptions?)null),
                    v => JsonSerializer.Deserialize<List<string>>(v, (JsonSerializerOptions?)null) ?? new List<string>()
                );
        });
    }
}
