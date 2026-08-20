namespace StyleSync.Api.Common.Shared;

/// <summary>
/// Common audit fields for all entities. Inherit from this in your module's models
/// instead of duplicating CreatedAt/UpdatedAt everywhere.
/// </summary>
public abstract class BaseEntity
{
    public int Id { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }
}
