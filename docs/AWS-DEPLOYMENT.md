# 🚀 Deploying .NET Aspire to AWS

This guide covers deploying .NET Aspire applications to AWS using multiple strategies. Choose the approach that best fits your requirements and complexity needs.

## 🎯 Deployment Strategy Overview

| Strategy                            | Best For                | Complexity | Scalability | Cost     |
| ----------------------------------- | ----------------------- | ---------- | ----------- | -------- |
| **Container Apps (ECS)**            | Production workloads    | Medium     | High        | Medium   |
| **App Service (Elastic Beanstalk)** | Simple web apps         | Low        | Medium      | Low      |
| **Kubernetes (EKS)**                | Enterprise/Complex apps | High       | Very High   | High     |
| **Serverless (Lambda)**             | Event-driven apps       | Medium     | Auto        | Very Low |

## 🐳 Option 1: AWS ECS (Recommended)

Deploy Aspire services as containers using Amazon Elastic Container Service.

### **Prerequisites**

```bash
# Install AWS CLI and configure credentials
aws configure

# Install Docker
docker --version

# Install ECS CLI (optional)
ecs-cli --version
```

### **Step 1: Containerize Each Service**

Create `Dockerfile` for each service:

**API Service Dockerfile:**

```dockerfile
# src/AspireAwsStack.ApiService/Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["src/AspireAwsStack.ApiService/AspireAwsStack.ApiService.csproj", "src/AspireAwsStack.ApiService/"]
COPY ["src/AspireAwsStack.ServiceDefaults/AspireAwsStack.ServiceDefaults.csproj", "src/AspireAwsStack.ServiceDefaults/"]
RUN dotnet restore "src/AspireAwsStack.ApiService/AspireAwsStack.ApiService.csproj"
COPY . .
WORKDIR "/src/src/AspireAwsStack.ApiService"
RUN dotnet build "AspireAwsStack.ApiService.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "AspireAwsStack.ApiService.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "AspireAwsStack.ApiService.dll"]
```

**Blazor Web Dockerfile:**

```dockerfile
# src/AspireAwsStack.Web/Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["src/AspireAwsStack.Web/AspireAwsStack.Web.csproj", "src/AspireAwsStack.Web/"]
COPY ["src/AspireAwsStack.ServiceDefaults/AspireAwsStack.ServiceDefaults.csproj", "src/AspireAwsStack.ServiceDefaults/"]
RUN dotnet restore "src/AspireAwsStack.Web/AspireAwsStack.Web.csproj"
COPY . .
WORKDIR "/src/src/AspireAwsStack.Web"
RUN dotnet build "AspireAwsStack.Web.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "AspireAwsStack.Web.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "AspireAwsStack.Web.dll"]
```

### **Step 2: Create ECS Task Definition**

```json
{
  "family": "aspire-aws-stack",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::YOUR_ACCOUNT:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::YOUR_ACCOUNT:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "api-service",
      "image": "YOUR_ACCOUNT.dkr.ecr.REGION.amazonaws.com/aspire-api:latest",
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "S3_BUCKET_NAME",
          "value": "aspire-aws-images-prod"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/aspire-aws-stack",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "api"
        }
      }
    },
    {
      "name": "web-service",
      "image": "YOUR_ACCOUNT.dkr.ecr.REGION.amazonaws.com/aspire-web:latest",
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "API_SERVICE_URL",
          "value": "http://api-service:8080"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/aspire-aws-stack",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "web"
        }
      }
    }
  ]
}
```

### **Step 3: Deploy with CloudFormation**

Create an enhanced CloudFormation template that includes ECS resources:

```json
{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Description": "Complete Aspire AWS Stack with ECS deployment",
  "Resources": {
    "VPC": {
      "Type": "AWS::EC2::VPC",
      "Properties": {
        "CidrBlock": "10.0.0.0/16",
        "EnableDnsHostnames": true,
        "EnableDnsSupport": true
      }
    },
    "ECSCluster": {
      "Type": "AWS::ECS::Cluster",
      "Properties": {
        "ClusterName": "aspire-aws-stack-cluster"
      }
    },
    "ECSService": {
      "Type": "AWS::ECS::Service",
      "Properties": {
        "Cluster": { "Ref": "ECSCluster" },
        "TaskDefinition": { "Ref": "ECSTaskDefinition" },
        "DesiredCount": 2,
        "LaunchType": "FARGATE"
      }
    }
  }
}
```

## 🌐 Option 2: AWS Elastic Beanstalk

For simpler deployments, use Elastic Beanstalk for web applications.

### **Prepare for Beanstalk Deployment**

1. **Modify Web Project for Beanstalk:**

   ```bash
   # Remove Aspire-specific dependencies for standalone deployment
   dotnet remove package Aspire.StackExchange.Redis.OutputCaching
   ```

2. **Create deployment package:**

   ```bash
   dotnet publish src/AspireAwsStack.Web -c Release -o ./publish
   cd publish
   zip -r ../aspire-web-app.zip .
   ```

3. **Deploy via AWS CLI:**

   ```bash
   # Create Beanstalk application
   aws elasticbeanstalk create-application --application-name aspire-web-app

   # Create environment
   aws elasticbeanstalk create-environment \
     --application-name aspire-web-app \
     --environment-name aspire-web-prod \
     --solution-stack-name "64bit Amazon Linux 2023 v3.1.0 running .NET 8"
   ```

## ☁️ Option 3: AWS Lambda (Serverless)

Deploy API endpoints as serverless functions.

### **Install Lambda Tools**

```bash
dotnet tool install -g Amazon.Lambda.Tools
```

### **Modify API for Lambda**

```csharp
// Add to AspireAwsStack.ApiService
public class LambdaEntryPoint : Amazon.Lambda.AspNetCoreServer.APIGatewayProxyFunction
{
    protected override void Init(IWebHostBuilder builder)
    {
        builder
            .UseContentRoot(Directory.GetCurrentDirectory())
            .UseStartup<Startup>()
            .UseLambdaServer();
    }
}
```

### **Deploy to Lambda**

```bash
cd src/AspireAwsStack.ApiService
dotnet lambda deploy-function AspireAwsStackApi \
  --function-role arn:aws:iam::YOUR_ACCOUNT:role/lambda-execution-role
```

## 🔧 Production Configuration

### **Environment Variables for Production**

```bash
# Set production environment variables
export ASPNETCORE_ENVIRONMENT=Production
export S3_BUCKET_NAME=aspire-aws-images-prod
export AWS_REGION=us-east-1
export ConnectionStrings__DefaultConnection="your-production-connection"
```

### **Security Best Practices**

- Use **IAM roles** instead of access keys
- Enable **VPC endpoints** for S3 access
- Configure **Application Load Balancer** with SSL
- Set up **CloudWatch** logging and monitoring
- Use **AWS Secrets Manager** for sensitive data

### **Monitoring and Observability**

```bash
# Enable CloudWatch Container Insights
aws logs create-log-group --log-group-name /ecs/aspire-aws-stack

# Set up X-Ray tracing for distributed tracing
aws xray create-service-map --service-names aspire-api,aspire-web
```

## 🚀 CI/CD Pipeline Example

Create a GitHub Actions workflow for automated deployment:

```yaml
# .github/workflows/deploy-to-aws.yml
name: Deploy to AWS ECS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Build and push Docker images
        run: |
          aws ecr get-login-password | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
          docker build -t aspire-api src/AspireAwsStack.ApiService
          docker tag aspire-api:latest $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/aspire-api:latest
          docker push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/aspire-api:latest

      - name: Update ECS service
        run: |
          aws ecs update-service --cluster aspire-cluster --service aspire-service --force-new-deployment
```

## 💡 Deployment Tips

1. **Start Small**: Begin with Elastic Beanstalk for proof-of-concept
2. **Use ECS for Production**: Better control and scalability
3. **Leverage CloudFormation**: Infrastructure as Code for repeatability
4. **Monitor Everything**: CloudWatch, X-Ray, and Application Insights
5. **Security First**: IAM roles, VPC, and encrypted storage
6. **Cost Optimization**: Use Fargate Spot, reserved instances, and lifecycle policies

## 📋 Pre-Deployment Checklist

- [ ] AWS CLI configured with appropriate permissions
- [ ] Docker installed and running
- [ ] CloudFormation templates tested
- [ ] Environment variables configured
- [ ] Monitoring and logging set up
- [ ] Security groups and IAM roles created
- [ ] Database and storage resources provisioned
- [ ] Load balancers and DNS configured
- [ ] CI/CD pipeline tested
- [ ] Rollback strategy defined

## 🆘 Deployment Troubleshooting

### **ECS Deployment Issues**

- **Container fails to start**: Check CloudWatch logs for startup errors
- **Task definition validation errors**: Verify CPU/memory configurations
- **Service discovery failures**: Ensure proper network configuration

### **Elastic Beanstalk Issues**

- **Deployment package too large**: Exclude unnecessary files from publish
- **Environment health issues**: Check application logs in Beanstalk console
- **Platform version compatibility**: Ensure .NET version matches platform

### **Lambda Deployment Issues**

- **Package size limits**: Use deployment packages or container images for large apps
- **Cold start performance**: Consider provisioned concurrency for critical endpoints
- **Memory/timeout configuration**: Adjust based on application requirements

## 🔗 Additional Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Elastic Beanstalk .NET Guide](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/dotnet-core-tutorial.html)
- [AWS Lambda .NET Guide](https://docs.aws.amazon.com/lambda/latest/dg/lambda-csharp.html)
- [.NET Aspire Documentation](https://learn.microsoft.com/en-us/dotnet/aspire/)
- [AWS CloudFormation Templates](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/)

---

📚 **Need Help?** Check the main [README.md](../README.md) for project overview and local development setup.
