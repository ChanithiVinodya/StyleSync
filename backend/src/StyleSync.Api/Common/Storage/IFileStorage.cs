using System.IO;
using System.Threading.Tasks;

namespace StyleSync.Api.Common.Storage;

public class FileStorageResult
{
    public string Url { get; set; } = string.Empty;
    public string StorageKey { get; set; } = string.Empty;
}

public interface IFileStorage
{
    Task<FileStorageResult> UploadAsync(Stream stream, string fileName, string contentType, string folder);
    Task DeleteAsync(string storageKey);
}
