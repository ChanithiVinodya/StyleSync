using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Models;

namespace StyleSync.Api.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Quote> Quotes => Set<Quote>();
        public DbSet<QuoteItem> QuoteItems => Set<QuoteItem>();
        public DbSet<QuoteVersion> QuoteVersions => Set<QuoteVersion>();
        public DbSet<QuoteVersionItem> QuoteVersionItems => Set<QuoteVersionItem>();
        public DbSet<Contract> Contracts => Set<Contract>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<Quote>(entity =>
            {
                entity.Property(q => q.TotalCost).HasColumnType("decimal(12,2)");
                entity.Property(q => q.Status).HasConversion<string>().HasMaxLength(35);

                entity.HasMany(q => q.Items)
                      .WithOne(i => i.Quote)
                      .HasForeignKey(i => i.QuoteId)
                      .OnDelete(DeleteBehavior.Cascade);

                entity.HasMany(q => q.Versions)
                      .WithOne(v => v.Quote)
                      .HasForeignKey(v => v.QuoteId)
                      .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(q => q.Contract)
                      .WithOne(c => c.Quote)
                      .HasForeignKey<Contract>(c => c.QuoteId)
                      .OnDelete(DeleteBehavior.Restrict);

                entity.HasIndex(q => q.ProjectRequestId);
                entity.HasIndex(q => q.DesignerId);
                entity.HasIndex(q => q.Status);
            });

            modelBuilder.Entity<QuoteVersion>(entity =>
            {
                entity.Property(v => v.MaterialsSubtotal).HasColumnType("decimal(12,2)");
                entity.Property(v => v.LaborSubtotal).HasColumnType("decimal(12,2)");
                entity.Property(v => v.DesignFee).HasColumnType("decimal(12,2)");
                entity.Property(v => v.ContingencyAmount).HasColumnType("decimal(12,2)");
                entity.Property(v => v.TaxAmount).HasColumnType("decimal(12,2)");
                entity.Property(v => v.TotalCost).HasColumnType("decimal(12,2)");

                entity.HasMany(v => v.Items)
                      .WithOne(i => i.QuoteVersion)
                      .HasForeignKey(i => i.QuoteVersionId)
                      .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(v => new { v.QuoteId, v.VersionNumber }).IsUnique();
            });

            modelBuilder.Entity<QuoteVersionItem>(entity =>
            {
                entity.Property(i => i.UnitCost).HasColumnType("decimal(12,2)");
                entity.Property(i => i.LineTotal).HasColumnType("decimal(12,2)");
                entity.Property(i => i.Category).HasConversion<string>().HasMaxLength(25);
            });

            modelBuilder.Entity<QuoteItem>(entity =>
            {
                entity.Property(i => i.UnitCost).HasColumnType("decimal(12,2)");
                entity.Property(i => i.LineTotal).HasColumnType("decimal(12,2)");
                entity.Property(i => i.Category).HasConversion<string>().HasMaxLength(25);
            });

            modelBuilder.Entity<Contract>(entity =>
            {
                entity.Property(c => c.TotalAmount).HasColumnType("decimal(12,2)");
                entity.Property(c => c.Status).HasConversion<string>().HasMaxLength(35);

                entity.HasIndex(c => c.QuoteId).IsUnique();
                entity.HasIndex(c => c.ProjectRequestId);
                entity.HasIndex(c => c.DesignerId);
                entity.HasIndex(c => c.ClientId);
                entity.HasIndex(c => c.Status);
            });
        }
    }
}
