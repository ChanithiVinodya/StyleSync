using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using StyleSync.Api.Modules.ProjectRequests.Models.Entities;

namespace StyleSync.Api.Modules.ProjectRequests.Data;

public class ProjectRequestConfigurations : IEntityTypeConfiguration<ProjectRequest>,
                                            IEntityTypeConfiguration<MoodboardImage>,
                                            IEntityTypeConfiguration<SuggestedPalette>,
                                            IEntityTypeConfiguration<RequestStatusHistory>
{
    public void Configure(EntityTypeBuilder<ProjectRequest> builder)
    {
        builder.HasKey(x => x.Id);

        builder.Property(x => x.RoomType)
            .HasConversion<string>()
            .HasMaxLength(50);
            
        builder.Property(x => x.Status)
            .HasConversion<string>()
            .HasMaxLength(50);
            
        builder.Property(x => x.Budget)
            .HasColumnType("decimal(18,2)");
            
        builder.Property(x => x.RoomSizeSqFt)
            .HasColumnType("decimal(18,2)");

        builder.Ignore(x => x.RequestedStyleTags);

        builder.HasIndex(x => new { x.ClientId, x.Status });
        builder.HasIndex(x => x.Status);
        builder.HasIndex(x => x.CreatedAt);
        builder.HasIndex(x => x.RoomType);

        builder.HasOne(x => x.Client)
            .WithMany()
            .HasForeignKey(x => x.ClientId)
            .OnDelete(DeleteBehavior.Cascade);
            
        builder.HasOne(x => x.FlaggedByUser)
            .WithMany()
            .HasForeignKey(x => x.FlaggedByUserId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasMany(x => x.MoodboardImages)
            .WithOne(x => x.ProjectRequest)
            .HasForeignKey(x => x.ProjectRequestId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(x => x.SuggestedPalettes)
            .WithOne(x => x.ProjectRequest)
            .HasForeignKey(x => x.ProjectRequestId)
            .OnDelete(DeleteBehavior.Cascade);
            
        builder.HasMany(x => x.StatusHistories)
            .WithOne(x => x.ProjectRequest)
            .HasForeignKey(x => x.ProjectRequestId)
            .OnDelete(DeleteBehavior.Cascade);
    }

    public void Configure(EntityTypeBuilder<MoodboardImage> builder)
    {
        builder.HasKey(x => x.Id);
        builder.HasIndex(x => x.ProjectRequestId);
    }

    public void Configure(EntityTypeBuilder<SuggestedPalette> builder)
    {
        builder.HasKey(x => x.Id);
        builder.HasIndex(x => x.ProjectRequestId);
    }

    public void Configure(EntityTypeBuilder<RequestStatusHistory> builder)
    {
        builder.HasKey(x => x.Id);
        
        builder.Property(x => x.FromStatus)
            .HasConversion<string>()
            .HasMaxLength(50);
            
        builder.Property(x => x.ToStatus)
            .HasConversion<string>()
            .HasMaxLength(50);
            
        builder.HasIndex(x => x.ProjectRequestId);
        
        builder.HasOne(x => x.ChangedByUser)
            .WithMany()
            .HasForeignKey(x => x.ChangedByUserId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
