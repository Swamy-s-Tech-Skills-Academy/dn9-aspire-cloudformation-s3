using AspireAwsStack.Web.Models;
using Microsoft.AspNetCore.Components.Forms;
using System.Text;
using System.Text.Json;

namespace AspireAwsStack.Web.Services;

public interface IImageUploadService
{
    Task<ImageUploadResult?> UploadImageAsync(IBrowserFile file, CancellationToken cancellationToken = default);
}

public class ImageUploadService : IImageUploadService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<ImageUploadService> _logger;

    public ImageUploadService(HttpClient httpClient, ILogger<ImageUploadService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<ImageUploadResult?> UploadImageAsync(IBrowserFile file, CancellationToken cancellationToken = default)
    {
        try
        {
            // Validate file
            if (!IsValidImageFile(file))
            {
                throw new ArgumentException("Invalid file type or size");
            }

            // Create multipart form data
            using var content = new MultipartFormDataContent();
            using var fileStream = file.OpenReadStream(ImageConstants.MaxFileSizeBytes, cancellationToken);
            using var streamContent = new StreamContent(fileStream);

            streamContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(file.ContentType);
            content.Add(streamContent, "file", file.Name);

            // Upload to API
            var response = await _httpClient.PostAsync("/api/images/upload", content, cancellationToken);

            if (response.IsSuccessStatusCode)
            {
                var jsonResponse = await response.Content.ReadAsStringAsync(cancellationToken);
                return JsonSerializer.Deserialize<ImageUploadResult>(jsonResponse, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });
            }
            else
            {
                var error = await response.Content.ReadAsStringAsync(cancellationToken);
                _logger.LogError("Upload failed: {StatusCode} - {Error}", response.StatusCode, error);
                throw new HttpRequestException($"Upload failed: {response.StatusCode} - {error}");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading image: {FileName}", file.Name);
            throw;
        }
    }

    private static bool IsValidImageFile(IBrowserFile file)
    {
        // Check file size
        if (file.Size > ImageConstants.MaxFileSizeBytes)
        {
            return false;
        }

        // Check content type
        if (!ImageConstants.AllowedContentTypes.Contains(file.ContentType, StringComparer.OrdinalIgnoreCase))
        {
            return false;
        }

        // Check file extension
        var extension = Path.GetExtension(file.Name).ToLowerInvariant();
        return ImageConstants.AllowedExtensions.Contains(extension);
    }
}
