using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;

namespace StyleSync.Api.Common.Storage;

public class LocalFileStorageService : IFileStorage
{
    private readonly string _uploadFolder;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public LocalFileStorageService(IWebHostEnvironment env, IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
        _uploadFolder = Path.Combine(env.ContentRootPath, "uploads");
        if (!Directory.Exists(_uploadFolder))
        {
            Directory.CreateDirectory(_uploadFolder);
        }
    }

    public async Task<FileStorageResult> UploadAsync(Stream stream, string fileName, string contentType, string folder)
    {
        var sanitizedFolder = folder.Replace('/', Path.DirectorySeparatorChar).Replace('\\', Path.DirectorySeparatorChar);
        var targetDir = Path.Combine(_uploadFolder, sanitizedFolder);
        if (!Directory.Exists(targetDir))
        {
            Directory.CreateDirectory(targetDir);
        }

        var ext = Path.GetExtension(fileName);
        if (string.IsNullOrEmpty(ext))
        {
            ext = contentType switch
            {
                "image/png" => ".png",
                "image/webp" => ".webp",
                _ => ".jpg"
            };
        }

        var uniqueFileName = $"{Guid.NewGuid()}{ext}";
        var filePath = Path.Combine(targetDir, uniqueFileName);

        if (stream.CanSeek)
        {
            stream.Position = 0;
        }
        using (var fileStream = new FileStream(filePath, FileMode.Create, FileAccess.Write))
        {
            await stream.CopyToAsync(fileStream);
        }

        var relativePath = $"uploads/{folder.Trim('/')}/{uniqueFileName}".Replace('\\', '/');

        var request = _httpContextAccessor.HttpContext?.Request;
        var baseUrl = request != null
            ? $"{request.Scheme}://{request.Host}"
            : "http://localhost:5000";

        return new FileStorageResult
        {
            StorageKey = relativePath,
            Url = $"{baseUrl}/{relativePath}"
        };
    }

    public Task DeleteAsync(string storageKey)
    {
        try
        {
            var cleanKey = storageKey.TrimStart('/').Replace("uploads/", "");
            var fullPath = Path.Combine(_uploadFolder, cleanKey.Replace('/', Path.DirectorySeparatorChar).Replace('\\', Path.DirectorySeparatorChar));
            if (File.Exists(fullPath))
            {
                File.Delete(fullPath);
            }
        }
        catch
        {
            // Ignore error on file delete
        }

        return Task.CompletedTask;
    }
}
