using Amazon;
using Aspire.Hosting.AWS;
using Aspire.Hosting.AWS.CloudFormation;

IDistributedApplicationBuilder builder = DistributedApplication.CreateBuilder(args);

// Set up a configuration for the AWS SDK for .NET.
IAWSSDKConfig awsConfig = builder.AddAWSSDKConfig()
                        .WithProfile("default")
                        .WithRegion(RegionEndpoint.USEast1);

IResourceBuilder<ICloudFormationTemplateResource> cloudFormationStack = builder.AddAWSCloudFormationTemplate("AspireAwsStackResources", "infrastructure/resources.template")
    .WithReference(awsConfig);

IResourceBuilder<RedisResource> cache = builder.AddRedis("cache");

IResourceBuilder<ProjectResource> apiService = builder.AddProject<Projects.AspireAwsStack_ApiService>("apiservice")
                                                    .WithReference(cloudFormationStack)
                                                    .WaitFor(cloudFormationStack)
                                                    .WithEnvironment("AWS__S3__BucketName", cloudFormationStack.GetOutput("BucketName"))
                                                    .WithReference(cache)
                                                    .WaitFor(cache);

builder.AddProject<Projects.AspireAwsStack_Web>("webfrontend")
    .WithExternalHttpEndpoints()
    .WithReference(cache)
    .WaitFor(cache)
    .WithReference(apiService)
    .WaitFor(apiService);

builder.Build().Run();
