using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using StyleSync.Api.Modules.Designers.Models;

namespace StyleSync.Api.Modules.Designers.Data;

public class DesignerProfileConfiguration : IEntityTypeConfiguration<DesignerProfile>
{
    public void Configure(EntityTypeBuilder<DesignerProfile> builder)
    {
        builder.ToTable("DesignerProfiles");
        builder.HasKey(x => x.Id);
        
        builder.Property(x => x.Name).IsRequired().HasMaxLength(100);
        builder.Property(x => x.Specialty).HasMaxLength(100);
        builder.Property(x => x.Location).HasMaxLength(100);
        builder.Property(x => x.MatchRate).HasColumnType("decimal(5,2)");
        builder.Property(x => x.Rating).HasColumnType("decimal(3,2)");
        
        builder.HasOne(x => x.User)
            .WithOne()
            .HasForeignKey<DesignerProfile>(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
