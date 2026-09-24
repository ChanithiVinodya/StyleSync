using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using StyleSync.Api.Modules.ProjectRequests.Models;

namespace StyleSync.Api.Modules.ProjectRequests.Data;

public class ProjectRequestConfiguration : IEntityTypeConfiguration<ProjectRequest>
{
    public void Configure(EntityTypeBuilder<ProjectRequest> builder)
    {
        builder.ToTable("ProjectRequests");

        builder.HasKey(r => r.Id);

        builder.Property(r => r.Title)
            .IsRequired()
            .HasMaxLength(150);

        builder.Property(r => r.Description)
            .IsRequired()
            .HasMaxLength(2000);

        builder.Property(r => r.RoomType)
            .HasConversion<string>()
            .HasMaxLength(50);

        builder.Property(r => r.Status)
            .HasConversion<string>()
            .HasMaxLength(50);

        builder.Property(r => r.BudgetMin)
            .HasColumnType("numeric(12,2)");

        builder.Property(r => r.BudgetMax)
            .HasColumnType("numeric(12,2)");

        builder.Property(r => r.StylePreferences)
            .HasMaxLength(500);

        builder.Property(r => r.SpecialRequirements)
            .HasMaxLength(1000);

        builder.Property(r => r.RejectionReason)
            .HasMaxLength(500);

        // Foreign key to AppUser (Client)
        builder.HasOne(r => r.Client)
            .WithMany()
            .HasForeignKey(r => r.ClientId)
            .OnDelete(DeleteBehavior.Restrict);

        // Indexes for common query patterns
        builder.HasIndex(r => r.ClientId);
        builder.HasIndex(r => r.Status);
        builder.HasIndex(r => r.CreatedAtUtc);
    }
}
