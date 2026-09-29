using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using StyleSync.Api.Modules.ProjectRequests.Models;

namespace StyleSync.Api.Modules.ProjectRequests.Data;

public class SuggestedPaletteConfiguration : IEntityTypeConfiguration<SuggestedPalette>
{
    public void Configure(EntityTypeBuilder<SuggestedPalette> builder)
    {
        builder.ToTable("SuggestedPalettes");

        builder.HasKey(p => p.Id);

        builder.Property(p => p.HexCode)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(p => p.ColorName)
            .HasMaxLength(100);

        builder.HasIndex(p => p.ProjectRequestId);
    }
}
