namespace StyleSync.Api.Configuration;

public class JwtSettings
{
    public const string SectionName = "Jwt";

    public string Key { get; set; } = string.Empty;
    public string Issuer { get; set; } = "StyleSync";
    public string Audience { get; set; } = "StyleSyncClient";
    public int ExpiryMinutes { get; set; } = 60;
}
