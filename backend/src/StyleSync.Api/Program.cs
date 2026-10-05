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
using StyleSync.Api.Modules.Designers.Services;
using StyleSync.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// ---- Configuration ----
builder.Services.Configure<JwtSettings>(builder.Configuration.GetSection(JwtSettings.SectionName));
var jwtSettings = builder.Configuration.GetSection(JwtSettings.SectionName).Get<JwtSettings>() ?? new JwtSettings();

// ---- Project Requests Module ----
var requestRules = builder.Configuration.GetSection("RequestRules").Get<StyleSync.Api.Modules.ProjectRequests.Configuration.RequestRules>() ?? new StyleSync.Api.Modules.ProjectRequests.Configuration.RequestRules();
builder.Services.AddSingleton(requestRules);
builder.Services.AddScoped<StyleSync.Api.Modules.ProjectRequests.Services.RequestValidationRules>();
builder.Services.AddScoped<StyleSync.Api.Modules.ProjectRequests.Services.RequestStatusService>();
builder.Services.AddScoped<StyleSync.Api.Modules.ProjectRequests.Services.IWorkflowStarter, StyleSync.Api.Modules.ProjectRequests.Services.MockWorkflowStarter>();
builder.Services.AddScoped<StyleSync.Api.Modules.ProjectRequests.Services.RequestQueryService>();
var azureBlobConn = builder.Configuration.GetConnectionString("AzureBlobStorage");
if (!string.IsNullOrEmpty(azureBlobConn) && !azureBlobConn.Contains("UseDevelopmentStorage=true", StringComparison.OrdinalIgnoreCase))
{
    builder.Services.AddScoped<StyleSync.Api.Common.Storage.IFileStorage, StyleSync.Api.Common.Storage.AzureBlobStorageService>();
}
else
{
    builder.Services.AddScoped<StyleSync.Api.Common.Storage.IFileStorage, StyleSync.Api.Common.Storage.LocalFileStorageService>();
}

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

    var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = System.IO.Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath))
    {
        options.IncludeXmlComments(xmlPath);
    }
});

// DbContexts
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddDbContext<StyleSync.Api.Data.AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// Designer Services
builder.Services.AddScoped<ICapacityGuardService, CapacityGuardService>();
builder.Services.AddScoped<IMatchScoreEngine, MatchScoreEngine>();
builder.Services.AddScoped<IDesignerService, DesignerService>();

// Identity & Auth Services
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentUser, CurrentUser>();
builder.Services.AddScoped<IPasswordHasher<AppUser>, PasswordHasher<AppUser>>();
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IAuthService, AuthService>();

// Quotes & Contracts Services & Integration Adapters (Student 3)
builder.Services.AddScoped<StyleSync.Api.Services.IQuotationEngine, StyleSync.Api.Services.QuotationEngine>();
builder.Services.AddScoped<StyleSync.Api.Services.IBudgetGuard, StyleSync.Api.Services.BudgetGuard>();
builder.Services.AddScoped<StyleSync.Api.Services.IQuoteExportService, StyleSync.Api.Services.QuoteExportService>();
builder.Services.AddScoped<StyleSync.Api.Integrations.IScopeSource, StyleSync.Api.Integrations.AiScopeSourceAdapter>();
builder.Services.AddSingleton<StyleSync.Api.Integrations.IProjectRequestProvider, StyleSync.Api.Integrations.StubProjectRequestProvider>();
builder.Services.AddScoped<StyleSync.Api.Integrations.ICurrentUserContext, StyleSync.Api.Integrations.HttpContextUserContext>();
builder.Services.AddScoped<StyleSync.Api.Integrations.IApprovalGateResumer, StyleSync.Api.Integrations.LangGraphApprovalGateResumer>();

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
        if (builder.Environment.IsDevelopment())
        {
            policy.SetIsOriginAllowed(_ => true)
                .AllowAnyHeader()
                .AllowAnyMethod()
                .AllowCredentials();
        }
        else
        {
            policy.WithOrigins(
                    builder.Configuration["Cors:ReactAppUrl"] ?? "http://localhost:5173")
                .AllowAnyHeader()
                .AllowAnyMethod()
                .AllowCredentials();
        }
    });
});

var app = builder.Build();

// ---- Middleware pipeline ----
app.UseMiddleware<ExceptionHandlingMiddleware>();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
else
{
    app.UseHttpsRedirection();
}

app.UseCors("AllowFrontend");

var uploadsDir = Path.Combine(app.Environment.ContentRootPath, "uploads");
if (!Directory.Exists(uploadsDir))
{
    Directory.CreateDirectory(uploadsDir);
}

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(uploadsDir),
    RequestPath = "/uploads"
});

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestampUtc = DateTime.UtcNow }));

// Seed initial Admin user idempotently
await DbSeeder.SeedAdminUserAsync(app.Services, app.Configuration);

// Seed component 2
await StyleSync.Api.Modules.ProjectRequests.Configuration.ProjectRequestsSeeder.SeedAsync(app.Services);

app.Run();

// Exposed for WebApplicationFactory in integration tests
public partial class Program { }
