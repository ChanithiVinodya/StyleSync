using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.Designers.Services;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// ---- Services ----
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddScoped<ICapacityGuardService, CapacityGuardService>();
builder.Services.AddScoped<IDesignerService, DesignerService>();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins(
                builder.Configuration["Cors:ReactAppUrl"] ?? "http://localhost:5173")
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

// TODO (any student, once auth is implemented): AddAuthentication().AddJwtBearer(...)
// and AddAuthorization() with role-based policies for Client / Designer / ProjectManager / Administrator.

var app = builder.Build();

// ---- Middleware pipeline ----
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors("AllowFrontend");
// app.UseAuthentication(); // enable once JWT is wired up
app.UseAuthorization();
app.MapControllers();

app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestampUtc = DateTime.UtcNow }));

app.Run();

// Exposed for WebApplicationFactory in integration tests
public partial class Program { }
