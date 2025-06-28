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

# Copy project files and restore dependencies (optimizes Docker layer caching)
COPY ["src/AspireAwsStack.Web/AspireAwsStack.Web.csproj", "src/AspireAwsStack.Web/"]
COPY ["src/AspireAwsStack.ServiceDefaults/AspireAwsStack.ServiceDefaults.csproj", "src/AspireAwsStack.ServiceDefaults/"]
RUN dotnet restore "src/AspireAwsStack.Web/AspireAwsStack.Web.csproj"

# Copy all source code
COPY . .
WORKDIR "/src/src/AspireAwsStack.Web"
RUN dotnet build "AspireAwsStack.Web.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "AspireAwsStack.Web.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Add health check endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["dotnet", "AspireAwsStack.Web.dll"]
```

### **Step 2: Build and Push to ECR**

Create ECR repositories and push images:

```bash
# Create ECR repositories
aws ecr create-repository --repository-name aspire-api --region us-east-1
aws ecr create-repository --repository-name aspire-web --region us-east-1

# Get login token
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build and tag images
docker build -f src/AspireAwsStack.ApiService/Dockerfile -t aspire-api .
docker build -f src/AspireAwsStack.Web/Dockerfile -t aspire-web .

# Tag for ECR
docker tag aspire-api:latest $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/aspire-api:latest
docker tag aspire-web:latest $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/aspire-web:latest

# Push to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/aspire-api:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/aspire-web:latest
```

### **Step 3: Complete CloudFormation Template**

Create a production-ready CloudFormation template with all necessary resources:

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

Create a production-ready CloudFormation template with all necessary resources:

```yaml
# infrastructure/ecs-complete-stack.yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Complete Aspire AWS Stack with ECS Fargate, ALB, and VPC'

Parameters:
  EnvironmentName:
    Description: Environment name prefix
    Type: String
    Default: 'aspire-prod'
  
  VpcCIDR:
    Description: CIDR block for VPC
    Type: String
    Default: '10.0.0.0/16'
  
  PublicSubnet1CIDR:
    Type: String
    Default: '10.0.1.0/24'
  
  PublicSubnet2CIDR:
    Type: String
    Default: '10.0.2.0/24'
  
  PrivateSubnet1CIDR:
    Type: String
    Default: '10.0.3.0/24'
  
  PrivateSubnet2CIDR:
    Type: String
    Default: '10.0.4.0/24'

  ApiImageUri:
    Description: ECR URI for API service
    Type: String
    
  WebImageUri:
    Description: ECR URI for Web service
    Type: String

  S3BucketName:
    Description: S3 bucket name for images
    Type: String

Resources:
  # VPC and Networking
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCIDR
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-VPC

  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-IGW

  InternetGatewayAttachment:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      InternetGatewayId: !Ref InternetGateway
      VpcId: !Ref VPC

  # Public Subnets
  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: !Ref PublicSubnet1CIDR
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName} Public Subnet (AZ1)

  PublicSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: !Ref PublicSubnet2CIDR
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName} Public Subnet (AZ2)

  # Private Subnets
  PrivateSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: !Ref PrivateSubnet1CIDR
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName} Private Subnet (AZ1)

  PrivateSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: !Ref PrivateSubnet2CIDR
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName} Private Subnet (AZ2)

  # NAT Gateways
  NatGateway1EIP:
    Type: AWS::EC2::EIP
    DependsOn: InternetGatewayAttachment
    Properties:
      Domain: vpc

  NatGateway1:
    Type: AWS::EC2::NatGateway
    Properties:
      AllocationId: !GetAtt NatGateway1EIP.AllocationId
      SubnetId: !Ref PublicSubnet1

  # Route Tables
  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName} Public Routes

  DefaultPublicRoute:
    Type: AWS::EC2::Route
    DependsOn: InternetGatewayAttachment
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  PublicSubnet1RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref PublicSubnet1

  PublicSubnet2RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref PublicSubnet2

  PrivateRouteTable1:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName} Private Routes (AZ1)

  DefaultPrivateRoute1:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref PrivateRouteTable1
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NatGateway1

  PrivateSubnet1RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PrivateRouteTable1
      SubnetId: !Ref PrivateSubnet1

  PrivateSubnet2RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PrivateRouteTable1
      SubnetId: !Ref PrivateSubnet2

  # Security Groups
  ALBSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for Application Load Balancer
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-ALB-SG

  ECSSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for ECS tasks
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 8080
          ToPort: 8080
          SourceSecurityGroupId: !Ref ALBSecurityGroup
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-ECS-SG

  # Application Load Balancer
  ApplicationLoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: !Sub ${EnvironmentName}-ALB
      Scheme: internet-facing
      Type: application
      Subnets:
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2
      SecurityGroups:
        - !Ref ALBSecurityGroup

  ALBListener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      DefaultActions:
        - Type: forward
          TargetGroupArn: !Ref WebTargetGroup
      LoadBalancerArn: !Ref ApplicationLoadBalancer
      Port: 80
      Protocol: HTTP

  # Target Groups
  WebTargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Name: !Sub ${EnvironmentName}-Web-TG
      Port: 8080
      Protocol: HTTP
      VpcId: !Ref VPC
      TargetType: ip
      HealthCheckPath: /health
      HealthCheckProtocol: HTTP
      HealthCheckIntervalSeconds: 30
      HealthCheckTimeoutSeconds: 5
      HealthyThresholdCount: 2
      UnhealthyThresholdCount: 5

  ApiTargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Name: !Sub ${EnvironmentName}-Api-TG
      Port: 8080
      Protocol: HTTP
      VpcId: !Ref VPC
      TargetType: ip
      HealthCheckPath: /health
      HealthCheckProtocol: HTTP

  # API Listener Rule
  ApiListenerRule:
    Type: AWS::ElasticLoadBalancingV2::ListenerRule
    Properties:
      Actions:
        - Type: forward
          TargetGroupArn: !Ref ApiTargetGroup
      Conditions:
        - Field: path-pattern
          Values: ['/api/*']
      ListenerArn: !Ref ALBListener
      Priority: 100

  # ECS Cluster
  ECSCluster:
    Type: AWS::ECS::Cluster
    Properties:
      ClusterName: !Sub ${EnvironmentName}-cluster
      CapacityProviders:
        - FARGATE
        - FARGATE_SPOT
      DefaultCapacityProviderStrategy:
        - CapacityProvider: FARGATE
          Weight: 1

  # IAM Roles
  ECSTaskExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Statement:
          - Effect: Allow
            Principal:
              Service: ecs-tasks.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

  ECSTaskRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Statement:
          - Effect: Allow
            Principal:
              Service: ecs-tasks.amazonaws.com
            Action: sts:AssumeRole
      Policies:
        - PolicyName: S3Access
          PolicyDocument:
            Statement:
              - Effect: Allow
                Action:
                  - s3:GetObject
                  - s3:PutObject
                  - s3:DeleteObject
                Resource: !Sub 'arn:aws:s3:::${S3BucketName}/*'

  # CloudWatch Logs
  CloudWatchLogsGroup:
    Type: AWS::Logs::LogGroup
    Properties:
      LogGroupName: !Sub /ecs/${EnvironmentName}
      RetentionInDays: 7

  # Separate Task Definitions for Better Isolation
  ApiTaskDefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      Family: !Sub ${EnvironmentName}-api-task
      NetworkMode: awsvpc
      RequiresCompatibilities:
        - FARGATE
      Cpu: 256
      Memory: 512
      ExecutionRoleArn: !Ref ECSTaskExecutionRole
      TaskRoleArn: !Ref ECSTaskRole
      ContainerDefinitions:
        - Name: api-service
          Image: !Ref ApiImageUri
          PortMappings:
            - ContainerPort: 8080
              Protocol: tcp
          Environment:
            - Name: S3_BUCKET_NAME
              Value: !Ref S3BucketName
            - Name: ASPNETCORE_ENVIRONMENT
              Value: Production
            - Name: ASPNETCORE_URLS
              Value: http://+:8080
          LogConfiguration:
            LogDriver: awslogs
            Options:
              awslogs-group: !Ref CloudWatchLogsGroup
              awslogs-region: !Ref AWS::Region
              awslogs-stream-prefix: api
          HealthCheck:
            Command:
              - CMD-SHELL
              - curl -f http://localhost:8080/health || exit 1
            Interval: 30
            Timeout: 5
            Retries: 3
            StartPeriod: 60

  WebTaskDefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      Family: !Sub ${EnvironmentName}-web-task
      NetworkMode: awsvpc
      RequiresCompatibilities:
        - FARGATE
      Cpu: 256
      Memory: 512
      ExecutionRoleArn: !Ref ECSTaskExecutionRole
      TaskRoleArn: !Ref ECSTaskRole
      ContainerDefinitions:
        - Name: web-service
          Image: !Ref WebImageUri
          PortMappings:
            - ContainerPort: 8080
              Protocol: tcp
          Environment:
            - Name: API_SERVICE_URL
              Value: !Sub http://${ApplicationLoadBalancer.DNSName}/api
            - Name: ASPNETCORE_ENVIRONMENT
              Value: Production
            - Name: ASPNETCORE_URLS
              Value: http://+:8080
          LogConfiguration:
            LogDriver: awslogs
            Options:
              awslogs-group: !Ref CloudWatchLogsGroup
              awslogs-region: !Ref AWS::Region
              awslogs-stream-prefix: web
          HealthCheck:
            Command:
              - CMD-SHELL
              - curl -f http://localhost:8080/health || exit 1
            Interval: 30
            Timeout: 5
            Retries: 3
            StartPeriod: 60

  # ECS Services
  ApiService:
    Type: AWS::ECS::Service
    DependsOn: ApiListenerRule
    Properties:
      ServiceName: !Sub ${EnvironmentName}-api-service
      Cluster: !Ref ECSCluster
      TaskDefinition: !Ref ApiTaskDefinition
      DesiredCount: 2
      LaunchType: FARGATE
      NetworkConfiguration:
        AwsvpcConfiguration:
          SecurityGroups:
            - !Ref ECSSecurityGroup
          Subnets:
            - !Ref PrivateSubnet1
            - !Ref PrivateSubnet2
          AssignPublicIp: DISABLED
      LoadBalancers:
        - ContainerName: api-service
          ContainerPort: 8080
          TargetGroupArn: !Ref ApiTargetGroup
      DeploymentConfiguration:
        MaximumPercent: 200
        MinimumHealthyPercent: 100
        RollingUpdateConfig:
          MaximumPercent: 200
          MinimumHealthyPercent: 100

  WebService:
    Type: AWS::ECS::Service
    DependsOn: ALBListener
    Properties:
      ServiceName: !Sub ${EnvironmentName}-web-service
      Cluster: !Ref ECSCluster
      TaskDefinition: !Ref WebTaskDefinition
      DesiredCount: 2
      LaunchType: FARGATE
      NetworkConfiguration:
        AwsvpcConfiguration:
          SecurityGroups:
            - !Ref ECSSecurityGroup
          Subnets:
            - !Ref PrivateSubnet1
            - !Ref PrivateSubnet2
          AssignPublicIp: DISABLED
      LoadBalancers:
        - ContainerName: web-service
          ContainerPort: 8080
          TargetGroupArn: !Ref WebTargetGroup
      DeploymentConfiguration:
        MaximumPercent: 200
        MinimumHealthyPercent: 100
        RollingUpdateConfig:
          MaximumPercent: 200
          MinimumHealthyPercent: 100

  # Auto Scaling
  ApiAutoScalingTarget:
    Type: AWS::ApplicationAutoScaling::ScalableTarget
    Properties:
      MaxCapacity: 10
      MinCapacity: 2
      ResourceId: !Sub service/${ECSCluster}/${ApiService.Name}
      RoleARN: !Sub arn:aws:iam::${AWS::AccountId}:role/aws-service-role/ecs.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService
      ScalableDimension: ecs:service:DesiredCount
      ServiceNamespace: ecs

  ApiAutoScalingPolicy:
    Type: AWS::ApplicationAutoScaling::ScalingPolicy
    Properties:
      PolicyName: !Sub ${EnvironmentName}-api-scaling-policy
      PolicyType: TargetTrackingScaling
      ScalingTargetId: !Ref ApiAutoScalingTarget
      TargetTrackingScalingPolicyConfiguration:
        PredefinedMetricSpecification:
          PredefinedMetricType: ECSServiceAverageCPUUtilization
        TargetValue: 70

  WebAutoScalingTarget:
    Type: AWS::ApplicationAutoScaling::ScalableTarget
    Properties:
      MaxCapacity: 10
      MinCapacity: 2
      ResourceId: !Sub service/${ECSCluster}/${WebService.Name}
      RoleARN: !Sub arn:aws:iam::${AWS::AccountId}:role/aws-service-role/ecs.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService
      ScalableDimension: ecs:service:DesiredCount
      ServiceNamespace: ecs

  WebAutoScalingPolicy:
    Type: AWS::ApplicationAutoScaling::ScalingPolicy
    Properties:
      PolicyName: !Sub ${EnvironmentName}-web-scaling-policy
      PolicyType: TargetTrackingScaling
      ScalingTargetId: !Ref WebAutoScalingTarget
      TargetTrackingScalingPolicyConfiguration:
        PredefinedMetricSpecification:
          PredefinedMetricType: ECSServiceAverageCPUUtilization
        TargetValue: 70

Outputs:
  VPC:
    Description: VPC ID
    Value: !Ref VPC
    Export:
      Name: !Sub ${EnvironmentName}-VPC

  LoadBalancerUrl:
    Description: Load Balancer URL
    Value: !Sub http://${ApplicationLoadBalancer.DNSName}
    Export:
      Name: !Sub ${EnvironmentName}-ALB-URL

  ApiUrl:
    Description: API Service URL
    Value: !Sub http://${ApplicationLoadBalancer.DNSName}/api
    Export:
      Name: !Sub ${EnvironmentName}-API-URL

  ECSCluster:
    Description: ECS Cluster Name
    Value: !Ref ECSCluster
    Export:
      Name: !Sub ${EnvironmentName}-ECSCluster

  ApiService:
    Description: API Service Name
    Value: !Ref ApiService
    Export:
      Name: !Sub ${EnvironmentName}-ApiService

  WebService:
    Description: Web Service Name
    Value: !Ref WebService
    Export:
      Name: !Sub ${EnvironmentName}-WebService
```

### **Step 4: Deploy the Stack**

Deploy using AWS CLI:

```bash
# Deploy the complete stack
aws cloudformation deploy \
  --template-file infrastructure/ecs-complete-stack.yaml \
  --stack-name aspire-ecs-stack \
  --parameter-overrides \
    EnvironmentName=aspire-prod \
    ApiImageUri=$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/aspire-api:latest \
    WebImageUri=$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/aspire-web:latest \
    S3BucketName=aspire-aws-images-prod \
  --capabilities CAPABILITY_IAM

# Get the Load Balancer URL
aws cloudformation describe-stacks \
  --stack-name aspire-ecs-stack \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerUrl`].OutputValue' \
  --output text
```

## 🌐 Option 2: AWS Elastic Beanstalk

For simpler deployments, use Elastic Beanstalk for web applications.

> **⚠️ Important Considerations for Aspire Applications:**
>
> Elastic Beanstalk deploys **standalone applications** without Aspire's orchestration layer. This means:
>
> - ❌ No automatic service discovery between services
> - ❌ No Aspire AppHost configuration and environment variables
> - ❌ No built-in Redis, database connections, or other Aspire-managed resources
> - ✅ You need to manually configure external services (Redis, databases, etc.)
> - ✅ Best suited for single-service deployments or simple web apps

### **Prepare for Beanstalk Deployment**

> **Important**: AWS Elastic Beanstalk support for .NET 9 may be limited. Check [AWS Beanstalk supported platforms](https://docs.aws.amazon.com/elasticbeanstalk/latest/platforms/platforms-supported.html) for current .NET 9 availability.

1. **Modify Web Project for Beanstalk:**

   ```bash
   # Remove Aspire-specific dependencies for standalone deployment
   # These packages depend on Aspire orchestration which won't be available in Beanstalk
   dotnet remove package Aspire.StackExchange.Redis.OutputCaching

   # Ensure project targets .NET 9
   # Check AspireAwsStack.Web.csproj has <TargetFramework>net9.0</TargetFramework>
   ```

   **Why remove Aspire packages?**

   - Aspire packages require the AppHost orchestrator for service discovery and configuration
   - Elastic Beanstalk deploys standalone applications without Aspire's orchestration layer
   - These dependencies would cause runtime failures without the Aspire infrastructure

   **Alternative for Beanstalk:** Replace with standard implementations:

   ```bash
   # Add standard Redis output caching instead of Aspire version
   dotnet add package Microsoft.Extensions.Caching.StackExchangeRedis

   # Update Program.cs to use standard Redis configuration
   # Replace: builder.AddRedisOutputCache("cache");
   # With: builder.Services.AddStackExchangeRedisCache(options => {
   #     options.Configuration = "your-redis-connection-string";
   # });
   ```

2. **Create deployment package for .NET 9:**

   ```bash
   # Publish for linux-x64 (Beanstalk runtime)
   dotnet publish src/AspireAwsStack.Web -c Release -r linux-x64 --self-contained false -o ./publish
   cd publish
   zip -r ../aspire-web-app.zip .
   ```

3. **Alternative: Use Docker with Beanstalk for .NET 9:**

   If .NET 9 isn't directly supported, use Docker deployment:

   ```dockerfile
   # Create Dockerfile in project root
   FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
   WORKDIR /app
   EXPOSE 5000

   FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
   WORKDIR /src
   COPY ["src/AspireAwsStack.Web/AspireAwsStack.Web.csproj", "src/AspireAwsStack.Web/"]
   RUN dotnet restore "src/AspireAwsStack.Web/AspireAwsStack.Web.csproj"
   COPY . .
   WORKDIR "/src/src/AspireAwsStack.Web"
   RUN dotnet publish "AspireAwsStack.Web.csproj" -c Release -o /app/publish

   FROM base AS final
   WORKDIR /app
   COPY --from=publish /app/publish .
   ENTRYPOINT ["dotnet", "AspireAwsStack.Web.dll"]
   ```

   Then deploy using Beanstalk Docker platform:

   ```bash
   # Create Dockerrun.aws.json
   echo '{
     "AWSEBDockerrunVersion": "1",
     "Image": {
       "Name": "aspire-web:latest",
       "Update": "true"
     },
     "Ports": [
       {
         "ContainerPort": "5000"
       }
     ]
   }' > Dockerrun.aws.json

   # Deploy to Beanstalk with Docker
   aws elasticbeanstalk create-environment \
     --application-name aspire-web-app \
     --environment-name aspire-web-prod \
     --solution-stack-name "64bit Amazon Linux 2023 v4.2.0 running Docker"
   ```

4. **Deploy via AWS CLI:**

   ```bash
   # Check available .NET 9 solution stacks
   aws elasticbeanstalk list-available-solution-stacks --query "SolutionStacks[?contains(@, '.NET')]"

   # Create Beanstalk application
   aws elasticbeanstalk create-application --application-name aspire-web-app

   # Create environment with .NET 9
   aws elasticbeanstalk create-environment \
     --application-name aspire-web-app \
     --environment-name aspire-web-prod \
     --solution-stack-name "64bit Amazon Linux 2023 v4.0.0 running .NET 9"
   ```

   > **Note**: If the exact .NET 9 solution stack name differs, use the `list-available-solution-stacks` command above to find the correct name for .NET 9.

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
