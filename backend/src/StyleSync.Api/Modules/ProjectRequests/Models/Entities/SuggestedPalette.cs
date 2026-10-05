using System;

namespace StyleSync.Api.Modules.ProjectRequests.Models.Entities;

public class SuggestedPalette
{
    public Guid Id { get; set; } = Guid.NewGuid();
    
    public Guid ProjectRequestId { get; set; }
    public ProjectRequest ProjectRequest { get; set; } = null!;
    
    public string Hex { get; set; } = string.Empty;
    
    public int Position { get; set; }
    
    public string Source { get; set; } = string.Empty;
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
