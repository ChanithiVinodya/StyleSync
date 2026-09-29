using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using StyleSync.Api.Modules.ProjectRequests.Models;

namespace StyleSync.Api.Modules.ProjectRequests.Data;

public class MoodboardImageConfiguration : IEntityTypeConfiguration<MoodboardImage>
{
    public void Configure(EntityTypeBuilder<MoodboardImage> builder)
    {
        builder.ToTable("MoodboardImages");

        builder.HasKey(i => i.Id);

        builder.Property(i => i.ImageUrl)
            .IsRequired()
            .HasMaxLength(2000);

        builder.Property(i => i.ImageType)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(i => i.StorageKey)
            .HasMaxLength(500);

        builder.HasIndex(i => i.ProjectRequestId);
    }
}
