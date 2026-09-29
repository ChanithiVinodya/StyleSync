using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using StyleSync.Api.Modules.ProjectRequests.Models;

namespace StyleSync.Api.Modules.ProjectRequests.Data;

public class ProjectRequestStatusHistoryConfiguration : IEntityTypeConfiguration<ProjectRequestStatusHistory>
{
    public void Configure(EntityTypeBuilder<ProjectRequestStatusHistory> builder)
    {
        builder.ToTable("ProjectRequestStatusHistories");

        builder.HasKey(h => h.Id);

        builder.Property(h => h.Status)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(h => h.Reason)
            .HasMaxLength(500);

        builder.Property(h => h.ChangedBy)
            .HasMaxLength(150);

        builder.HasIndex(h => h.ProjectRequestId);
    }
}
