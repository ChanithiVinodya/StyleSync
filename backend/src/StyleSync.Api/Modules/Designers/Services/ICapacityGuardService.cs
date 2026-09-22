using StyleSync.Api.Modules.Designers.Models;

namespace StyleSync.Api.Modules.Designers.Services;

public interface ICapacityGuardService
{
    /// <summary>
    /// Counts rows in the placeholder Contracts table where DesignerId = designerId AND Status = Active.
    /// </summary>
    Task<int> GetActiveProjectCountAsync(int designerId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Batch counts active contracts for a list of designer IDs.
    /// </summary>
    Task<Dictionary<int, int>> GetActiveProjectCountsAsync(IEnumerable<int> designerIds, CancellationToken cancellationToken = default);

    /// <summary>
    /// Determines if a designer is under capacity: GetActiveProjectCount(designerId) < designer.MaxConcurrentProjects.
    /// </summary>
    Task<bool> IsUnderCapacityAsync(int designerId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Synchronous capacity check given an already loaded designer profile and active project count.
    /// </summary>
    bool IsUnderCapacity(DesignerProfile designer, int activeProjectCount);

    /// <summary>
    /// Enforces the hard capacity guard filter on candidate designers.
    /// Designers at or over capacity (IsUnderCapacity == false) are excluded REGARDLESS of IsAvailable.
    /// </summary>
    Task<List<DesignerProfile>> FilterCandidatesUnderCapacityAsync(IEnumerable<DesignerProfile> designers, CancellationToken cancellationToken = default);
}
