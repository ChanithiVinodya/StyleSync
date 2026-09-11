using Microsoft.EntityFrameworkCore;
using StyleSync.Backend.Data;
using StyleSync.Backend.Services;
using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);

// Add Controllers with JSON Enum Converters
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
    });

builder.Services.AddHttpContextAccessor();

// Configure EF Core (InMemory for development/testing, or PostgreSQL if connection string is provided)
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (!string.IsNullOrEmpty(connectionString))
{
    builder.Services.AddDbContext<StyleSyncDbContext>(options =>
        options.UseNpgsql(connectionString));
}
else
{
    builder.Services.AddDbContext<StyleSyncDbContext>(options =>
        options.UseInMemoryDatabase("StyleSyncDb"));
}

// Register Photo Storage Service
builder.Services.AddScoped<IPhotoStorageService, LocalPhotoStorageService>();

// Register AI Service HttpClient
var aiServiceUrl = builder.Configuration.GetValue<string>("AIService:BaseUrl") ?? "http://localhost:8000";
builder.Services.AddHttpClient<IAIServiceClient, AIServiceClient>(client =>
{
    client.BaseAddress = new Uri(aiServiceUrl);
    client.Timeout = TimeSpan.FromSeconds(30);
});

// Register Project Request Service
builder.Services.AddScoped<IProjectRequestService, ProjectRequestService>();

// CORS configuration for React frontend & Flutter app
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

app.UseCors("AllowAll");
app.UseStaticFiles();

// Seed initial sample data for demonstration
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<StyleSyncDbContext>();
    db.Database.EnsureCreated();

    if (!db.ProjectRequests.Any())
    {
        var sampleRequest = new StyleSync.Backend.Domain.Entities.ProjectRequest
        {
            Id = Guid.Parse("11111111-1111-1111-1111-111111111111"),
            ClientId = "client-nimali",
            RoomType = "Bedroom",
            LengthFeet = 15,
            WidthFeet = 12,
            HeightFeet = 10,
            BudgetLkr = 250000,
            PreferredStyles = new List<string> { "Modern", "Minimalist" },
            Description = "I want a simple room. I like white and light brown colours. I don't want too much furniture.",
            Status = StyleSync.Backend.Domain.Enums.ProjectRequestStatus.ProposalReady,
            CreatedAt = DateTime.UtcNow.AddHours(-2),
            UpdatedAt = DateTime.UtcNow
        };

        // 4 uploaded room photos for this sample request
        var photoUrls = new[]
        {
            ("https://images.unsplash.com/photo-1616594039964-ae9021a400a0?q=80&w=800&auto=format&fit=crop", "sample/bedroom-1.jpg"),
            ("https://images.unsplash.com/photo-1631049307264-da0ec9d70304?q=80&w=800&auto=format&fit=crop", "sample/bedroom-2.jpg"),
            ("https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?q=80&w=800&auto=format&fit=crop", "sample/bedroom-3.jpg"),
            ("https://images.unsplash.com/photo-1540518614846-7eded433c457?q=80&w=800&auto=format&fit=crop", "sample/bedroom-4.jpg")
        };
        foreach (var (url, key) in photoUrls)
        {
            sampleRequest.Photos.Add(new StyleSync.Backend.Domain.Entities.ProjectRequestPhoto
            {
                ProjectRequestId = sampleRequest.Id,
                PhotoUrl = url,
                StorageKey = key,
                UploadedAt = DateTime.UtcNow
            });
        }

        sampleRequest.StyleAnalysis = new StyleSync.Backend.Domain.Entities.StyleAnalysisResult
        {
            ProjectRequestId = sampleRequest.Id,
            PrimaryStyle = "Modern",
            SecondaryStyle = "Minimalist",
            ConfidenceScore = 93.4,
            RecommendedColors = new List<string> { "#FFFFFF (White)", "#D7C4B7 (Light Brown)", "#F5F5F7 (Warm Grey)" },
            DetectedFeatures = new List<string> { "Visual Feature Extraction (4 Uploaded Photos)", "Clean Architectural Lines", "Uncluttered Spatial Flow", "Soft Natural Daylight" },
            AnalysisSummary = "Our AI Style Analysis Agent analyzed 4 uploaded room photos and evaluated client preferences for your Bedroom. The space is ideal for a Modern design direction with subtle Minimalist accents, yielding a calculated 93.4% compatibility score.",
            ConceptRenderUrl = "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=1000&auto=format&fit=crop",
            AnalyzedAt = DateTime.UtcNow
        };

        db.ProjectRequests.Add(sampleRequest);
        db.SaveChanges();
    }
}

app.MapControllers();

app.Run();
