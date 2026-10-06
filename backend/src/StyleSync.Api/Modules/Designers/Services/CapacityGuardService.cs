using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.Designers.Models;

namespace StyleSync.Api.Modules.Designers.Services;

public class CapacityGuardService : ICapacityGuardService
{
    private readonly AppDbContext _context;

    public CapacityGuardService(AppDbContext context)
    {
        _context = context;
    }

    /// <inheritdoc />
    public async Task<int> GetActiveProjectCountAsync(int designerId, CancellationToken cancellationToken = default)
    {
        var userId = await _context.DesignerProfiles
            .Where(d => d.Id == designerId)
            .Select(d => d.UserId)
            .FirstOrDefaultAsync(cancellationToken);

        if (userId == Guid.Empty) return 0;

        return await _context.Contracts
            .AsNoTracking()
            .CountAsync(c => c.DesignerId == userId && c.Status == StyleSync.Api.Models.ContractStatus.Active, cancellationToken);
    }

    /// <inheritdoc />
    public async Task<Dictionary<int, int>> GetActiveProjectCountsAsync(IEnumerable<int> designerIds, CancellationToken cancellationToken = default)
    {
        var idsList = designerIds.Distinct().ToList();
        if (!idsList.Any())
        {
            return new Dictionary<int, int>();
        }

        var profileMappings = await _context.DesignerProfiles
            .Where(d => idsList.Contains(d.Id))
            .Select(d => new { d.Id, d.UserId })
            .ToDictionaryAsync(d => d.UserId, d => d.Id, cancellationToken);

        var userIds = profileMappings.Keys.ToList();

        var activeCounts = await _context.Contracts
            .AsNoTracking()
            .Where(c => userIds.Contains(c.DesignerId) && c.Status == StyleSync.Api.Models.ContractStatus.Active)
            .GroupBy(c => c.DesignerId)
            .Select(g => new { UserId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.UserId, x => x.Count, cancellationToken);

        var counts = new Dictionary<int, int>();
        foreach (var id in idsList)
        {
            counts[id] = 0;
        }

        foreach (var kvp in activeCounts)
        {
            if (profileMappings.TryGetValue(kvp.Key, out var designerId))
            {
                counts[designerId] = kvp.Value;
            }
        }

        return counts;
    }

    /// <inheritdoc />
    public async Task<bool> IsUnderCapacityAsync(int designerId, CancellationToken cancellationToken = default)
    {
        var designer = await _context.DesignerProfiles
            .AsNoTracking()
            .FirstOrDefaultAsync(d => d.Id == designerId, cancellationToken);

        if (designer == null)
        {
            return false;
        }

        var activeCount = await GetActiveProjectCountAsync(designerId, cancellationToken);
        return IsUnderCapacity(designer, activeCount);
    }

    /// <inheritdoc />
    public bool IsUnderCapacity(DesignerProfile designer, int activeProjectCount)
    {
        // IsUnderCapacity = GetActiveProjectCount(designerId) < designer.MaxConcurrentProjects
        return activeProjectCount < designer.MaxConcurrentProjects;
    }

    /// <inheritdoc />
    public async Task<List<DesignerProfile>> FilterCandidatesUnderCapacityAsync(IEnumerable<DesignerProfile> designers, CancellationToken cancellationToken = default)
    {
        var designerList = designers.ToList();
        if (!designerList.Any())
        {
            return new List<DesignerProfile>();
        }

        var ids = designerList.Select(d => d.Id).ToList();
        var counts = await GetActiveProjectCountsAsync(ids, cancellationToken);

        // Hard filter: ANY designer where IsUnderCapacity is false is excluded REGARDLESS of IsAvailable
        return designerList
            .Where(d => IsUnderCapacity(d, counts.TryGetValue(d.Id, out var c) ? c : 0))
            .ToList();
    }
}
