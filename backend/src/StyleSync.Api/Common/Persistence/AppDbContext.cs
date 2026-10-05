using StyleSync.Api.Common.Identity;
using Microsoft.EntityFrameworkCore;

using StyleSync.Api.Modules.Designers.Models;

namespace StyleSync.Api.Common.Persistence;

/// <summary>
/// SHARED FILE - merge-conflict hotspot. Rules to keep conflicts low:
///  1. Do NOT put entity configuration logic here - use IEntityTypeConfiguration
///     classes in your own module's Data/ folder. OnModelCreating auto-discovers
///     them via ApplyConfigurationsFromAssembly, so you should rarely need to touch
///     this class at all.
///  2. When you add your first entity, add ONE DbSet line for it below, in your
///     own module's section only. Do not reorder or reformat other students' lines.
///  3. Coordinate migrations with the team before running `dotnet ef migrations add`
///     - only one migration should be "in flight" (created but not yet merged) at a time.
/// </summary>
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    // ---- Shared / Identity (already wired up) ----
    public DbSet<AppUser> Users => Set<AppUser>();

    // ---- Module: Designers (Student 1) ----
    public DbSet<DesignerProfile> DesignerProfiles => Set<DesignerProfile>();
    public DbSet<PortfolioItem> PortfolioItems => Set<PortfolioItem>();

    // ---- Module: Project Requests (Student 2) ----
    // TODO: add your first DbSet here, e.g.
    // public DbSet<ProjectRequest> ProjectRequests => Set<ProjectRequest>();

    // ---- Module: Quotes & Contracts (Student 3) ----
    public DbSet<ContractStub> Contracts => Set<ContractStub>();

    // ---- Module: Project Execution (Student 4) ----
    // TODO: add your first DbSet here, e.g.
    // public DbSet<ProjectMilestone> ProjectMilestones => Set<ProjectMilestone>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Auto-discovers every IEntityTypeConfiguration<T> in this assembly,
        // including ones inside each module's Data/ folder. You normally
        // don't need to add anything else here.
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }
}
