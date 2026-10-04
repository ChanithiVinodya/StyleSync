using System;
using System.IO;
using System.Threading.Tasks;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.Extensions.Configuration;

namespace StyleSync.Api.Common.Storage;

public class AzureBlobStorageService : IFileStorage
{
    private readonly BlobServiceClient _blobServiceClient;
    private readonly string _containerName;

    public AzureBlobStorageService(IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("AzureBlobStorage") ?? "UseDevelopmentStorage=true";
        _blobServiceClient = new BlobServiceClient(connectionString);
        _containerName = configuration["AzureBlobStorage:ContainerName"] ?? "stylesync-uploads";
    }

    public async Task<FileStorageResult> UploadAsync(Stream stream, string fileName, string contentType, string folder)
    {
        var containerClient = _blobServiceClient.GetBlobContainerClient(_containerName);
        await containerClient.CreateIfNotExistsAsync(PublicAccessType.Blob);

        var key = $"{folder}/{Guid.NewGuid()}{Path.GetExtension(fileName)}";
        var blobClient = containerClient.GetBlobClient(key);

        var headers = new BlobHttpHeaders { ContentType = contentType };
        stream.Position = 0;
        await blobClient.UploadAsync(stream, new BlobUploadOptions { HttpHeaders = headers });

        return new FileStorageResult
        {
            StorageKey = key,
            Url = blobClient.Uri.ToString()
        };
    }

    public async Task DeleteAsync(string storageKey)
    {
        var containerClient = _blobServiceClient.GetBlobContainerClient(_containerName);
        var blobClient = containerClient.GetBlobClient(storageKey);
        await blobClient.DeleteIfExistsAsync();
    }
}
