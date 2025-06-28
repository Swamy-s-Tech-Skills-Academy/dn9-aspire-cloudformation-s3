using AspireAwsStack.ServiceDefaults;
using AspireAwsStack.ApiService.Services;
using AspireAwsStack.ApiService.Models;
using Amazon.S3;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

// Add service defaults & Aspire client integrations.
builder.AddServiceDefaults();

// Add services to the container.
builder.Services.AddProblemDetails();
builder.Services.AddAntiforgery();

// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

// Configure AWS S3
builder.Services.AddScoped<IAmazonS3, AmazonS3Client>();
builder.Services.AddScoped<IS3ImageService, S3ImageService>();

// Add CORS for Blazor app
builder.Services.AddCors(options =>
{
    options.AddPolicy("BlazorPolicy", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
app.UseExceptionHandler();
app.UseCors("BlazorPolicy");
app.UseAntiforgery();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference(); // Add Scalar API documentation
}

// Image Upload API Endpoints
var imagesApi = app.MapGroup("/api/images")
    .WithTags("Images")
    .WithOpenApi();

imagesApi.MapPost("/upload", async (
    IFormFile file,
    IS3ImageService imageService,
    CancellationToken cancellationToken) =>
{
    if (file == null || file.Length == 0)
    {
        return Results.BadRequest("No file uploaded");
    }

    try
    {
        using var stream = file.OpenReadStream();
        var request = new ImageUploadRequest(
            FileName: file.FileName,
            ContentType: file.ContentType,
            ImageStream: stream
        );

        var result = await imageService.UploadImageAsync(request, cancellationToken);
        return Results.Ok(result);
    }
    catch (ArgumentException ex)
    {
        return Results.BadRequest(ex.Message);
    }
    catch (Exception ex)
    {
        return Results.Problem($"Upload failed: {ex.Message}");
    }
})
.WithName("UploadImage")
.WithSummary("Upload an image to S3")
.Accepts<IFormFile>("multipart/form-data")
.Produces<ImageUploadResult>()
.DisableAntiforgery();

// TODO: Add other endpoints later
// - GET /api/images (list images)
// - GET /api/images/{id} (get image)  
// - DELETE /api/images/{id} (delete image)

// Keep the original weather forecast endpoint for reference
string[] summaries = ["Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"];

app.MapGet("/weatherforecast", () =>
{
    var forecast = Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast
        (
            DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        ))
        .ToArray();
    return forecast;
})
.WithName("GetWeatherForecast");

app.MapDefaultEndpoints();

app.Run();

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}
