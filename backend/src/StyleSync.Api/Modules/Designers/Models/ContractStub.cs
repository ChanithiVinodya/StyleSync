namespace StyleSync.Api.Modules.Designers.Models;

public enum ContractStatus
{
    Active = 0,
    Completed = 1,
    Cancelled = 2
}

/// <summary>
/// Minimal placeholder table for Component 3/4 stubbing to compute ActiveProjectCount.
/// Contains ONLY Id, DesignerId, and Status.
/// </summary>
public class ContractStub
{
    public int Id { get; set; }
    public int DesignerId { get; set; }
    public ContractStatus Status { get; set; } = ContractStatus.Active;
}
