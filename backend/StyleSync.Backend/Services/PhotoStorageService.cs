namespace StyleSync.Backend.Services;

public interface IPhotoStorageService
{
    Task<(string PhotoUrl, string StorageKey)> UploadPhotoAsync(IFormFile file, Guid projectRequestId);
    Task DeletePhotoAsync(string storageKey);
}

public class LocalPhotoStorageService : IPhotoStorageService
{
    private readonly IWebHostEnvironment _env;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public LocalPhotoStorageService(IWebHostEnvironment env, IHttpContextAccessor httpContextAccessor)
    {
        _env = env;
        _httpContextAccessor = httpContextAccessor;
    }

    public async Task<(string PhotoUrl, string StorageKey)> UploadPhotoAsync(IFormFile file, Guid projectRequestId)
    {
        var uploadsFolder = Path.Combine(_env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot"), "uploads", projectRequestId.ToString());
        if (!Directory.Exists(uploadsFolder))
        {
            Directory.CreateDirectory(uploadsFolder);
        }

        var fileName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
        var filePath = Path.Combine(uploadsFolder, fileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        var request = _httpContextAccessor.HttpContext?.Request;
        var baseUrl = request != null ? $"{request.Scheme}://{request.Host}" : "http://localhost:5000";
        var photoUrl = $"{baseUrl}/uploads/{projectRequestId}/{fileName}";
        var storageKey = $"uploads/{projectRequestId}/{fileName}";

        return (photoUrl, storageKey);
    }

    public Task DeletePhotoAsync(string storageKey)
    {
        var filePath = Path.Combine(_env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot"), storageKey);
        if (File.Exists(filePath))
        {
            File.Delete(filePath);
        }
        return Task.CompletedTask;
    }
}
