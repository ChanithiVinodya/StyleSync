using System;
using System.Collections.Concurrent;
using System.IO;
using System.Threading.Tasks;

namespace StyleSync.Api.Common.Storage;

public class FakeFileStorage : IFileStorage
{
    private readonly ConcurrentDictionary<string, byte[]> _storage = new();

    public async Task<FileStorageResult> UploadAsync(Stream stream, string fileName, string contentType, string folder)
    {
        var key = $"{folder}/{Guid.NewGuid()}{Path.GetExtension(fileName)}";
        using var ms = new MemoryStream();
        await stream.CopyToAsync(ms);
        _storage[key] = ms.ToArray();

        return new FileStorageResult
        {
            StorageKey = key,
            Url = $"https://fake-storage.local/{key}"
        };
    }

    public Task DeleteAsync(string storageKey)
    {
        _storage.TryRemove(storageKey, out _);
        return Task.CompletedTask;
    }
}
