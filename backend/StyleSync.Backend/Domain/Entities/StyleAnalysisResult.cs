namespace StyleSync.Backend.Domain.Entities;

public class StyleAnalysisResult
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ProjectRequestId { get; set; }
    public string PrimaryStyle { get; set; } = string.Empty;
    public string SecondaryStyle { get; set; } = string.Empty;
    public double ConfidenceScore { get; set; } // 0.0 to 100.0 %
    public List<string> RecommendedColors { get; set; } = new();
    public List<string> DetectedFeatures { get; set; } = new();
    public string AnalysisSummary { get; set; } = string.Empty;
    public string ConceptRenderUrl { get; set; } = string.Empty;
    public DateTime AnalyzedAt { get; set; } = DateTime.UtcNow;
}
