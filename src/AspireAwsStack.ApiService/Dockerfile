# src/AspireAwsStack.ApiService/Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy project files and restore dependencies (optimizes Docker layer caching)
COPY ["src/AspireAwsStack.ApiService/AspireAwsStack.ApiService.csproj", "src/AspireAwsStack.ApiService/"]
COPY ["src/AspireAwsStack.ServiceDefaults/AspireAwsStack.ServiceDefaults.csproj", "src/AspireAwsStack.ServiceDefaults/"]
RUN dotnet restore "src/AspireAwsStack.ApiService/AspireAwsStack.ApiService.csproj"

# Copy all source code
COPY . .
WORKDIR "/src/src/AspireAwsStack.ApiService"
RUN dotnet build "AspireAwsStack.ApiService.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "AspireAwsStack.ApiService.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Add health check endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["dotnet", "AspireAwsStack.ApiService.dll"]
