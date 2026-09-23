using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Models;

namespace StyleSync.Api.Data
{
    // NOTE for the team: StyleSync is one modular monolith with one shared
    // DbContext (PRD section 11 — "Database: PostgreSQL, Backend only").
    // If a shared AppDbContext already exists in the repo, just copy the
    // three DbSet lines and the OnModelCreating block below into it instead
    // of using this file directly.
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Quote> Quotes => Set<Quote>();
        public DbSet<QuoteItem> QuoteItems => Set<QuoteItem>();
        public DbSet<Contract> Contracts => Set<Contract>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<Quote>(entity =>
            {
                entity.Property(q => q.TotalCost).HasColumnType("decimal(12,2)");
                entity.Property(q => q.Status).HasConversion<string>().HasMaxLength(30);

                entity.HasMany(q => q.Items)
                      .WithOne(i => i.Quote)
                      .HasForeignKey(i => i.QuoteId)
                      .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(q => q.Contract)
                      .WithOne(c => c.Quote)
                      .HasForeignKey<Contract>(c => c.QuoteId)
                      .OnDelete(DeleteBehavior.Restrict);

                entity.HasIndex(q => q.ProjectRequestId);
                entity.HasIndex(q => q.DesignerId);
                entity.HasIndex(q => q.Status);
            });

            modelBuilder.Entity<QuoteItem>(entity =>
            {
                entity.Property(i => i.UnitCost).HasColumnType("decimal(12,2)");
                entity.Property(i => i.LineTotal).HasColumnType("decimal(12,2)");
                entity.Property(i => i.Category).HasConversion<string>().HasMaxLength(20);
            });

            modelBuilder.Entity<Contract>(entity =>
            {
                entity.Property(c => c.TotalAmount).HasColumnType("decimal(12,2)");
                entity.Property(c => c.Status).HasConversion<string>().HasMaxLength(30);

                entity.HasIndex(c => c.QuoteId).IsUnique();
                entity.HasIndex(c => c.ProjectRequestId);
                entity.HasIndex(c => c.DesignerId);
                entity.HasIndex(c => c.ClientId);
                entity.HasIndex(c => c.Status);
            });
        }
    }
}
