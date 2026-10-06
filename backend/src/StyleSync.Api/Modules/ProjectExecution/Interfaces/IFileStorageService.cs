using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;

namespace StyleSync.Api.Modules.ProjectExecution.Interfaces;

public interface IFileStorageService
{
    Task<string> SaveFileAsync(IFormFile file, string directory = "uploads");
    Task<bool> DeleteFileAsync(string fileUrl);
}
