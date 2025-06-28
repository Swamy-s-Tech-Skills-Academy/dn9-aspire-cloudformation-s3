namespace AspireAwsStack.ApiService.Models;

public sealed record ImageUploadResult(
    string ImageId,
    string FileName,
    string ContentType,
    long SizeInBytes,
    string S3Key,
    string BucketName,
    DateTime UploadedAt,
    string Url
);

public sealed record ImageUploadRequest(
    string FileName,
    string ContentType,
    Stream ImageStream
);

public sealed record ImageMetadata(
    string ImageId,
    string FileName,
    string ContentType,
    long SizeInBytes,
    string S3Key,
    string BucketName,
    DateTime UploadedAt
);

public static class ImageUploadConstants
{
    public static readonly string[] AllowedContentTypes = [
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/gif",
        "image/webp"
    ];

    public const long MaxFileSizeInBytes = 10 * 1024 * 1024; // 10MB
    public const string S3KeyPrefix = "images/";
}
