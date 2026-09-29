using StyleSync.Api.Common.Shared;

namespace StyleSync.Api.Modules.ProjectRequests.Models;

public class SuggestedPalette : BaseEntity
{
    public int ProjectRequestId { get; set; }
    public ProjectRequest ProjectRequest { get; set; } = null!;

    public string HexCode { get; set; } = string.Empty;
    public string ColorName { get; set; } = string.Empty;
}
