using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using StyleSync.Api.Modules.Designers.Models;

namespace StyleSync.Api.Modules.Designers.Data;

public class PortfolioItemConfiguration : IEntityTypeConfiguration<PortfolioItem>
{
    public void Configure(EntityTypeBuilder<PortfolioItem> builder)
    {
        builder.ToTable("PortfolioItems");

        builder.HasKey(p => p.Id);

        builder.Property(p => p.Title)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(p => p.Description)
            .IsRequired()
            .HasMaxLength(2000);

        builder.Property(p => p.ImageUrl)
            .IsRequired()
            .HasMaxLength(1000);

        builder.Property(p => p.BudgetRangeLabel)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(p => p.ClientInitials)
            .IsRequired()
            .HasMaxLength(10);

        builder.Property(p => p.CompletionStatusBadge)
            .HasConversion<int>()
            .IsRequired();
    }
}
