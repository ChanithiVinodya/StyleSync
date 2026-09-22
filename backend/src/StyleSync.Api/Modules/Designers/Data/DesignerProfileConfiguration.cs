using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using StyleSync.Api.Modules.Designers.Models;

namespace StyleSync.Api.Modules.Designers.Data;

public class DesignerProfileConfiguration : IEntityTypeConfiguration<DesignerProfile>
{
    public void Configure(EntityTypeBuilder<DesignerProfile> builder)
    {
        builder.ToTable("DesignerProfiles");

        builder.HasKey(d => d.Id);

        builder.Property(d => d.DisplayName)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(d => d.Bio)
            .IsRequired()
            .HasMaxLength(2000);

        builder.Property(d => d.PriceRangeMin)
            .HasColumnType("decimal(18,2)")
            .IsRequired();

        builder.Property(d => d.PriceRangeMax)
            .HasColumnType("decimal(18,2)")
            .IsRequired();

        builder.Property(d => d.RatePerSqFt)
            .HasColumnType("decimal(18,2)")
            .IsRequired();

        builder.Property(d => d.AverageRating)
            .HasColumnType("decimal(3,2)");

        builder.Property(d => d.MaxConcurrentProjects)
            .HasDefaultValue(3)
            .IsRequired();

        builder.Property(d => d.IsAvailable)
            .HasDefaultValue(true)
            .IsRequired();

        builder.Property(d => d.ListingStatus)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(d => d.StyleTags)
            .HasColumnType("text[]");

        builder.Property(d => d.ServiceCategories)
            .HasColumnType("text[]");

        builder.HasOne(d => d.User)
            .WithOne()
            .HasForeignKey<DesignerProfile>(d => d.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(d => d.PortfolioItems)
            .WithOne(p => p.DesignerProfile)
            .HasForeignKey(p => p.DesignerProfileId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
