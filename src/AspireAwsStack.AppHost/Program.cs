var builder = DistributedApplication.CreateBuilder(args);

//// Set up a configuration for the AWS SDK for .NET.
//var awsConfig = builder.AddAWSSDKConfig()
//                        .WithProfile("dev")
//                        .WithRegion(RegionEndpoint.USWest2);

var cache = builder.AddRedis("cache");

var apiService = builder.AddProject<Projects.AspireAwsStack_ApiService>("apiservice");

builder.AddProject<Projects.AspireAwsStack_Web>("webfrontend")
    .WithExternalHttpEndpoints()
    .WithReference(cache)
    .WaitFor(cache)
    .WithReference(apiService)
    .WaitFor(apiService);

builder.Build().Run();
