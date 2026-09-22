using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using StyleSync.Api.Modules.Designers.Models;

namespace StyleSync.Api.Modules.Designers.Data;

public class ContractStubConfiguration : IEntityTypeConfiguration<ContractStub>
{
    public void Configure(EntityTypeBuilder<ContractStub> builder)
    {
        builder.ToTable("Contracts");

        builder.HasKey(c => c.Id);

        builder.Property(c => c.DesignerId)
            .IsRequired();

        builder.Property(c => c.Status)
            .HasConversion<int>()
            .IsRequired();
    }
}
