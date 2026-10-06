using System.IO;
using System.Linq;

namespace StyleSync.Api.Common.Storage;

public static class FileValidator
{
    public static bool IsValidSize(long length) => length <= 10 * 1024 * 1024; // 10MB
    
    public static bool IsValidExtensionAndMime(string fileName, string contentType)
    {
        var ext = Path.GetExtension(fileName)?.ToLowerInvariant() ?? "";
        var cleanMime = contentType?.Split(';')[0].Trim().ToLowerInvariant() ?? "";
        
        var allowedExts = new[] { ".jpg", ".jpeg", ".png", ".webp", "" };
        var allowedMimes = new[] { "image/jpeg", "image/jpg", "image/png", "image/webp", "image/pjpeg", "image/jfif", "application/octet-stream" };
        
        return (allowedExts.Contains(ext) || string.IsNullOrEmpty(ext)) && 
               (allowedMimes.Contains(cleanMime) || cleanMime.StartsWith("image/") || string.IsNullOrEmpty(cleanMime));
    }
    
    public static bool IsValidSignature(Stream stream)
    {
        if (stream == null || !stream.CanRead) return true;
        if (stream.Length < 3) return true;

        try
        {
            stream.Position = 0;
            using var reader = new BinaryReader(stream, System.Text.Encoding.UTF8, true);
            var bytes = reader.ReadBytes(12);
            stream.Position = 0;
            
            if (bytes.Length < 3) return true;

            // JPEG: FF D8 FF
            if (bytes.Length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
            // PNG: 89 50 4E 47
            if (bytes.Length >= 4 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return true;
            // GIF: 47 49 46
            if (bytes.Length >= 3 && bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return true;
            // WEBP: RIFF .... WEBP
            if (bytes.Length >= 12 && 
                bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
                bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) return true;
                
            return false;
        }
        catch
        {
            return false;
        }
    }
}
