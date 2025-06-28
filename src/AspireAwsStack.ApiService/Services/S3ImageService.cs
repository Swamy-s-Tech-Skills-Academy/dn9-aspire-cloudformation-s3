using Amazon.S3;
using Amazon.S3.Model;
using AspireAwsStack.ApiService.Models;

namespace AspireAwsStack.ApiService.Services;

public interface IS3ImageService
{
    Task<ImageUploadResult> UploadImageAsync(ImageUploadRequest request, CancellationToken cancellationToken = default);
}

public sealed class S3ImageService : IS3ImageService
{
    private readonly IAmazonS3 _s3Client;
    private readonly IConfiguration _configuration;
    private readonly ILogger<S3ImageService> _logger;

    public S3ImageService(IAmazonS3 s3Client, IConfiguration configuration, ILogger<S3ImageService> logger)
    {
        _s3Client = s3Client;
        _configuration = configuration;
        _logger = logger;
    }

    private string BucketName => _configuration["AWS:S3:BucketName"]
        ?? throw new InvalidOperationException("AWS S3 BucketName not configured");

    public async Task<ImageUploadResult> UploadImageAsync(ImageUploadRequest request, CancellationToken cancellationToken = default)
    {
        ValidateImageRequest(request);

        var imageId = Guid.NewGuid().ToString("N");
        var s3Key = $"{ImageUploadConstants.S3KeyPrefix}{imageId}/{request.FileName}";

        try
        {
            var putRequest = new PutObjectRequest
            {
                BucketName = BucketName,
                Key = s3Key,
                InputStream = request.ImageStream,
                ContentType = request.ContentType,
                Metadata =
                {
                    ["image-id"] = imageId,
                    ["original-filename"] = request.FileName,
                    ["uploaded-at"] = DateTime.UtcNow.ToString("O")
                }
            };

            var response = await _s3Client.PutObjectAsync(putRequest, cancellationToken);

            _logger.LogInformation("Successfully uploaded image {ImageId} to S3 bucket {BucketName}", imageId, BucketName);

            var imageUrl = $"https://{BucketName}.s3.amazonaws.com/{s3Key}";

            return new ImageUploadResult(
                ImageId: imageId,
                FileName: request.FileName,
                ContentType: request.ContentType,
                SizeInBytes: request.ImageStream.Length,
                S3Key: s3Key,
                BucketName: BucketName,
                UploadedAt: DateTime.UtcNow,
                Url: imageUrl
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to upload image {ImageId} to S3 bucket {BucketName}", imageId, BucketName);
            throw;
        }
    }

    private static void ValidateImageRequest(ImageUploadRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.FileName))
            throw new ArgumentException("File name is required", nameof(request.FileName));

        if (string.IsNullOrWhiteSpace(request.ContentType))
            throw new ArgumentException("Content type is required", nameof(request.ContentType));

        if (!ImageUploadConstants.AllowedContentTypes.Contains(request.ContentType.ToLowerInvariant()))
            throw new ArgumentException($"Content type {request.ContentType} is not supported", nameof(request.ContentType));

        if (request.ImageStream.Length > ImageUploadConstants.MaxFileSizeInBytes)
            throw new ArgumentException($"File size exceeds maximum allowed size of {ImageUploadConstants.MaxFileSizeInBytes} bytes", nameof(request.ImageStream));

        if (request.ImageStream.Length == 0)
            throw new ArgumentException("Image stream cannot be empty", nameof(request.ImageStream));
    }
}
