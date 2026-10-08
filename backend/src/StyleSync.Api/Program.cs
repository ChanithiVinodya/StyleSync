using System.Text;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using StyleSync.Api.Common.Identity;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Configuration;
using StyleSync.Api.Middleware;
using StyleSync.Api.Services;
using StyleSync.Api.Modules.ProjectExecution.Interfaces;
using StyleSync.Api.Modules.ProjectExecution.Services;
using StyleSync.Api.Modules.Designers.Services;

// Enable Npgsql legacy timestamp behavior to avoid UTC/Kind=Unspecified mismatches from mobile clients
AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);

var builder = WebApplication.CreateBuilder(args);

// ---- Configuration ----
builder.Services.Configure<JwtSettings>(builder.Configuration.GetSection(JwtSettings.SectionName));
var jwtSettings = builder.Configuration.GetSection(JwtSettings.SectionName).Get<JwtSettings>() ?? new JwtSettings();

// ---- Services ----
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
    });
builder.Services.AddEndpointsApiExplorer();

// Swagger with JWT Support
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "StyleSync API", Version = "v1" });
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter your JWT Bearer token."
    });
    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// DbContexts
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddHttpContextAccessor();

// Identity & Auth Services
builder.Services.AddScoped<IPasswordHasher<AppUser>, PasswordHasher<AppUser>>();
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<StyleSync.Api.Common.Identity.ICurrentUser, StyleSync.Api.Common.Identity.CurrentUser>();
builder.Services.AddScoped<StyleSync.Api.Integrations.ICurrentUserContext, StyleSync.Api.Integrations.HttpContextUserContext>();

// Domain Services
builder.Services.AddSingleton(new StyleSync.Api.Modules.ProjectRequests.Configuration.RequestRules());
builder.Services.AddScoped<StyleSync.Api.Modules.ProjectRequests.Services.RequestValidationRules>();
builder.Services.AddScoped<StyleSync.Api.Modules.ProjectRequests.Services.IWorkflowStarter, StyleSync.Api.Modules.ProjectRequests.Services.AiWorkflowStarter>();
builder.Services.AddScoped<StyleSync.Api.Modules.ProjectRequests.Services.PaletteService>();
builder.Services.AddScoped<StyleSync.Api.Common.Storage.IFileStorage, StyleSync.Api.Common.Storage.LocalFileStorageService>();
builder.Services.AddScoped<StyleSync.Api.Modules.ProjectRequests.Services.RequestQueryService>();
builder.Services.AddScoped<StyleSync.Api.Modules.ProjectRequests.Services.RequestStatusService>();

builder.Services.AddScoped<StyleSync.Api.Modules.Designers.Services.ICapacityGuardService, StyleSync.Api.Modules.Designers.Services.CapacityGuardService>();
builder.Services.AddScoped<StyleSync.Api.Modules.Designers.Services.IMatchScoreEngine, StyleSync.Api.Modules.Designers.Services.MatchScoreEngine>();
builder.Services.AddScoped<StyleSync.Api.Modules.Designers.Services.IDesignerService, StyleSync.Api.Modules.Designers.Services.DesignerService>();

builder.Services.AddScoped<StyleSync.Api.Services.IBudgetGuard, StyleSync.Api.Services.BudgetGuard>();
builder.Services.AddScoped<StyleSync.Api.Services.IQuotationEngine, StyleSync.Api.Services.QuotationEngine>();
builder.Services.AddScoped<StyleSync.Api.Services.IQuoteExportService, StyleSync.Api.Services.QuoteExportService>();

// Project Execution Services
builder.Services.AddScoped<IMilestoneService, MilestoneService>();
builder.Services.AddScoped<ITaskService, TaskService>();
builder.Services.AddScoped<ITaskDependencyService, TaskDependencyService>();
builder.Services.AddScoped<IDelayService, DelayService>();
builder.Services.AddScoped<IMaterialService, MaterialService>();
builder.Services.AddScoped<IProgressPhotoService, ProgressPhotoService>();
builder.Services.AddScoped<IFileStorageService, LocalFileStorageService>();
builder.Services.AddScoped<IProjectTimelineService, ProjectTimelineService>();
builder.Services.AddScoped<IProjectAnalyticsService, ProjectAnalyticsService>();

// Designers Services
builder.Services.AddScoped<IDesignerProfileService, DesignerProfileService>();

// JWT Authentication
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings.Issuer,
        ValidAudience = jwtSettings.Audience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings.Key)),
        ClockSkew = TimeSpan.FromSeconds(30)
    };
});

builder.Services.AddAuthorization();

// AI Service Client (Quotes & Contracts)
builder.Services.AddHttpClient("AiService", client =>
{
    var baseUrl = builder.Configuration["AiService:BaseUrl"] ?? "http://localhost:8000";
    client.BaseAddress = new Uri(baseUrl);
    client.Timeout = TimeSpan.FromSeconds(30);
});

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.SetIsOriginAllowed(origin => true)
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials();
    });
});

var app = builder.Build();

// ---- Middleware pipeline ----
app.UseMiddleware<ExceptionHandlingMiddleware>();

// Enable Swagger across environments for interactive documentation
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "StyleSync API v1");
    c.RoutePrefix = "swagger";
});

app.UseCors("AllowFrontend");
app.UseStaticFiles();

var uploadsPath = Path.Combine(app.Environment.ContentRootPath, "uploads");
if (!Directory.Exists(uploadsPath))
{
    Directory.CreateDirectory(uploadsPath);
}
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(uploadsPath),
    RequestPath = "/uploads"
});

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapGet("/", () => Results.Ok(new
{
    service = "StyleSync API",
    status = "Online",
    version = "v1",
    documentation = "/swagger",
    health = "/health",
    timestampUtc = DateTime.UtcNow
}));
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestampUtc = DateTime.UtcNow }));

// Seed initial Admin user idempotently
await DbSeeder.SeedAdminUserAsync(app.Services, app.Configuration);

app.Run();

// Exposed for WebApplicationFactory in integration tests
public partial class Program { }
