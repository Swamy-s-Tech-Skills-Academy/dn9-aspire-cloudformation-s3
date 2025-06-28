namespace AspireAwsStack.Web.Models;

public record ImageUploadResult(
    string ImageId,
    string FileName,
    string ContentType,
    long SizeInBytes,
    string S3Key,
    string BucketName,
    DateTime UploadedAt,
    string Url
);

public record ImageUploadRequest(
    string FileName,
    string ContentType,
    Stream ImageStream
);

public static class ImageConstants
{
    public static readonly string[] AllowedExtensions = [".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp"];
    public static readonly string[] AllowedContentTypes =
    [
        "image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp", "image/bmp"
    ];
    public const long MaxFileSizeBytes = 10 * 1024 * 1024; // 10MB
}
