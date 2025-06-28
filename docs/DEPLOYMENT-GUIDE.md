# 🚀 Quick Deployment Guide

This guide provides step-by-step instructions for deploying your .NET Aspire AWS Stack to production using AWS ECS.

## 🎯 Prerequisites

Before you begin, ensure you have:

- ✅ AWS CLI installed and configured with appropriate permissions
- ✅ Docker installed and running
- ✅ Access to an AWS account with ECS, ECR, CloudFormation, and S3 permissions
- ✅ The project cloned and built locally

### **Verify Prerequisites**

**Bash/Linux/macOS:**

```bash
# Check AWS CLI configuration
aws configure list
aws sts get-caller-identity

# Check Docker
docker --version
docker info

# Verify project structure
ls -la src/AspireAwsStack.AppHost/infrastructure/ecs-complete-stack.yaml
ls -la scripts/deploy-to-aws.sh
```

**PowerShell/Windows:**

```powershell
# Check AWS CLI configuration
aws configure list
aws sts get-caller-identity

# Check Docker
docker --version
docker info

# Verify project structure
Get-ChildItem -Path "src/AspireAwsStack.AppHost/infrastructure/ecs-complete-stack.yaml"
Get-ChildItem -Path "scripts/deploy-to-aws.sh"
```

---

## 🚀 Option 1: One-Command Deployment (Recommended)

### **Step 1: Choose Your Deployment Script**

We provide both Bash and PowerShell deployment scripts for your convenience:

- **`scripts/deploy-to-aws.sh`** - Bash script (Linux/macOS/WSL)
- **`scripts/deploy-to-aws.ps1`** - PowerShell script (Windows/Cross-platform)

**Bash/Linux/macOS:**

```bash
chmod +x scripts/deploy-to-aws.sh
```

**PowerShell/Windows:**

```powershell
# No setup required - PowerShell script is ready to run
# Ensure ExecutionPolicy allows script execution:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### **Step 2: Deploy Everything**

**Bash/Linux/macOS:**

```bash
# Deploy to production environment
./scripts/deploy-to-aws.sh aspire-prod us-east-1

# Or deploy to staging environment
./scripts/deploy-to-aws.sh aspire-staging us-west-2
```

**PowerShell/Windows (Recommended):**

```powershell
# Deploy to production environment
.\scripts\deploy-to-aws.ps1 -EnvironmentName "aspire-prod" -AwsRegion "us-east-1"

# Or deploy to staging environment
.\scripts\deploy-to-aws.ps1 -EnvironmentName "aspire-staging" -AwsRegion "us-west-2"

# With custom scaling parameters
.\scripts\deploy-to-aws.ps1 -EnvironmentName "aspire-prod" -AwsRegion "us-east-1" -MinCapacity 1 -MaxCapacity 5

# Alternative: Run bash script from PowerShell (requires Git Bash or WSL)
bash scripts/deploy-to-aws.sh aspire-prod us-east-1
```

### **Script Parameters**

**Bash Script (`deploy-to-aws.sh`):**

| Parameter        | Description                  | Default       | Example          |
| ---------------- | ---------------------------- | ------------- | ---------------- |
| Environment Name | Prefix for all AWS resources | `aspire-prod` | `aspire-staging` |
| AWS Region       | Target AWS region            | `us-east-1`   | `us-west-2`      |

**PowerShell Script (`deploy-to-aws.ps1`):**

| Parameter          | Description                  | Default       | Example          |
| ------------------ | ---------------------------- | ------------- | ---------------- |
| `-EnvironmentName` | Prefix for all AWS resources | `aspire-prod` | `aspire-staging` |
| `-AwsRegion`       | Target AWS region            | `us-east-1`   | `us-west-2`      |
| `-MinCapacity`     | Minimum number of ECS tasks  | `2`           | `1`              |
| `-MaxCapacity`     | Maximum number of ECS tasks  | `10`          | `5`              |
| `-TaskCpu`         | CPU units for ECS tasks      | `512`         | `256`            |
| `-TaskMemory`      | Memory (MB) for ECS tasks    | `1024`        | `512`            |

### **What the Script Does**

1. 📦 **Creates ECR repositories** (if they don't exist)
2. 🐳 **Builds Docker images** for API and Web services
3. ⬆️ **Pushes images to ECR** with proper tagging
4. ☁️ **Deploys CloudFormation stack** with complete infrastructure
5. 📋 **Outputs deployment results** with URLs and endpoints

---

## 🔧 Option 2: Manual Step-by-Step Deployment

If you prefer more control over each step, follow these manual commands:

### **Step 1: Set Environment Variables**

**Bash/Linux/macOS:**

```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-east-1
export ENVIRONMENT_NAME=aspire-prod
export S3_BUCKET_NAME=aspire-aws-images-${ENVIRONMENT_NAME}-$(date +%s)

echo "Deploying to:"
echo "  Account: $AWS_ACCOUNT_ID"
echo "  Region: $AWS_REGION"
echo "  Environment: $ENVIRONMENT_NAME"
echo "  S3 Bucket: $S3_BUCKET_NAME"
```

**PowerShell/Windows:**

```powershell
$AWS_ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
$AWS_REGION = "us-east-1"
$ENVIRONMENT_NAME = "aspire-prod"
$Timestamp = [int][double]::Parse((Get-Date -UFormat %s))
$S3_BUCKET_NAME = "aspire-aws-images-$ENVIRONMENT_NAME-$Timestamp"

Write-Host "Deploying to:" -ForegroundColor Green
Write-Host "  Account: $AWS_ACCOUNT_ID" -ForegroundColor Cyan
Write-Host "  Region: $AWS_REGION" -ForegroundColor Cyan
Write-Host "  Environment: $ENVIRONMENT_NAME" -ForegroundColor Cyan
Write-Host "  S3 Bucket: $S3_BUCKET_NAME" -ForegroundColor Cyan
```

### **Step 2: Create ECR Repositories**

**Bash/Linux/macOS:**

```bash
# Create repositories for container images
aws ecr create-repository --repository-name aspire-api --region $AWS_REGION
aws ecr create-repository --repository-name aspire-web --region $AWS_REGION

# Verify repositories were created
aws ecr describe-repositories --region $AWS_REGION --query 'repositories[].repositoryName'
```

**PowerShell/Windows:**

```powershell
# Create repositories for container images
aws ecr create-repository --repository-name aspire-api --region $AWS_REGION
aws ecr create-repository --repository-name aspire-web --region $AWS_REGION

# Verify repositories were created
aws ecr describe-repositories --region $AWS_REGION --query 'repositories[].repositoryName'
```

### **Step 3: Build and Push Docker Images**

**Bash/Linux/macOS:**

```bash
# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build Docker images
echo "Building API service image..."
docker build -f src/AspireAwsStack.ApiService/Dockerfile -t aspire-api .

echo "Building Web service image..."
docker build -f src/AspireAwsStack.Web/Dockerfile -t aspire-web .

# Tag images for ECR
docker tag aspire-api:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aspire-api:latest
docker tag aspire-web:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aspire-web:latest

# Push images to ECR
echo "Pushing API service image..."
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aspire-api:latest

echo "Pushing Web service image..."
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aspire-web:latest

echo "✅ Images pushed successfully!"
```

**PowerShell/Windows:**

```powershell
# Login to ECR
$loginCommand = "aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
Invoke-Expression $loginCommand

# Build Docker images
Write-Host "Building API service image..." -ForegroundColor Yellow
docker build -f src/AspireAwsStack.ApiService/Dockerfile -t aspire-api .

Write-Host "Building Web service image..." -ForegroundColor Yellow
docker build -f src/AspireAwsStack.Web/Dockerfile -t aspire-web .

# Tag images for ECR
$ApiImageUri = "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aspire-api:latest"
$WebImageUri = "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aspire-web:latest"

docker tag aspire-api:latest $ApiImageUri
docker tag aspire-web:latest $WebImageUri

# Push images to ECR
Write-Host "Pushing API service image..." -ForegroundColor Yellow
docker push $ApiImageUri

Write-Host "Pushing Web service image..." -ForegroundColor Yellow
docker push $WebImageUri

Write-Host "✅ Images pushed successfully!" -ForegroundColor Green
```

### **Step 4: Deploy CloudFormation Stack**

**Bash/Linux/macOS:**

```bash
# Deploy the complete infrastructure
aws cloudformation deploy \
  --template-file src/AspireAwsStack.AppHost/infrastructure/ecs-complete-stack.yaml \
  --stack-name ${ENVIRONMENT_NAME}-ecs-stack \
  --parameter-overrides \
    EnvironmentName=${ENVIRONMENT_NAME} \
    ApiImageUri=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/aspire-api:latest \
    WebImageUri=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/aspire-web:latest \
    S3BucketName=${S3_BUCKET_NAME} \
    MinCapacity=2 \
    MaxCapacity=10 \
    TaskCpu=512 \
    TaskMemory=1024 \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${AWS_REGION}
```

**PowerShell/Windows:**

```powershell
# Deploy the complete infrastructure
$deployCommand = @"
aws cloudformation deploy ``
  --template-file src/AspireAwsStack.AppHost/infrastructure/ecs-complete-stack.yaml ``
  --stack-name $ENVIRONMENT_NAME-ecs-stack ``
  --parameter-overrides ``
    EnvironmentName=$ENVIRONMENT_NAME ``
    ApiImageUri=$ApiImageUri ``
    WebImageUri=$WebImageUri ``
    S3BucketName=$S3_BUCKET_NAME ``
    MinCapacity=2 ``
    MaxCapacity=10 ``
    TaskCpu=512 ``
    TaskMemory=1024 ``
  --capabilities CAPABILITY_NAMED_IAM ``
  --region $AWS_REGION
"@

Invoke-Expression $deployCommand
```

### **Step 5: Get Deployment Outputs**

**Bash/Linux/macOS:**

```bash
# Wait for deployment to complete, then get outputs
echo "Getting deployment outputs..."

LOAD_BALANCER_URL=$(aws cloudformation describe-stacks \
  --stack-name ${ENVIRONMENT_NAME}-ecs-stack \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerUrl`].OutputValue' \
  --output text \
  --region ${AWS_REGION})

API_URL=$(aws cloudformation describe-stacks \
  --stack-name ${ENVIRONMENT_NAME}-ecs-stack \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiUrl`].OutputValue' \
  --output text \
  --region ${AWS_REGION})

S3_URL=$(aws cloudformation describe-stacks \
  --stack-name ${ENVIRONMENT_NAME}-ecs-stack \
  --query 'Stacks[0].Outputs[?OutputKey==`S3BucketUrl`].OutputValue' \
  --output text \
  --region ${AWS_REGION})

echo ""
echo "🎉 Deployment successful!"
echo "🌐 Application URL: $LOAD_BALANCER_URL"
echo "🔗 API URL: $API_URL"
echo "📦 S3 Bucket: $S3_URL"
```

**PowerShell/Windows:**

```powershell
# Wait for deployment to complete, then get outputs
Write-Host "Getting deployment outputs..." -ForegroundColor Yellow

$LOAD_BALANCER_URL = aws cloudformation describe-stacks `
  --stack-name "$ENVIRONMENT_NAME-ecs-stack" `
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerUrl`].OutputValue' `
  --output text `
  --region $AWS_REGION

$API_URL = aws cloudformation describe-stacks `
  --stack-name "$ENVIRONMENT_NAME-ecs-stack" `
  --query 'Stacks[0].Outputs[?OutputKey==`ApiUrl`].OutputValue' `
  --output text `
  --region $AWS_REGION

$S3_URL = aws cloudformation describe-stacks `
  --stack-name "$ENVIRONMENT_NAME-ecs-stack" `
  --query 'Stacks[0].Outputs[?OutputKey==`S3BucketUrl`].OutputValue' `
  --output text `
  --region $AWS_REGION

Write-Host ""
Write-Host "🎉 Deployment successful!" -ForegroundColor Green
Write-Host "🌐 Application URL: $LOAD_BALANCER_URL" -ForegroundColor Cyan
Write-Host "🔗 API URL: $API_URL" -ForegroundColor Cyan
Write-Host "📦 S3 Bucket: $S3_URL" -ForegroundColor Cyan
```

---

## 🔍 Post-Deployment Verification

### **1. Check Application Health**

**Bash/Linux/macOS:**

```bash
# Wait for services to start (5-10 minutes)
echo "Waiting for services to start..."
sleep 300

# Test health endpoints
echo "Testing health endpoints..."
curl -f $LOAD_BALANCER_URL/health || echo "❌ Web service health check failed"
curl -f $API_URL/health || echo "❌ API service health check failed"

echo "✅ Health checks completed"
```

**PowerShell/Windows:**

```powershell
# Wait for services to start (5-10 minutes)
Write-Host "Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 300

# Test health endpoints
Write-Host "Testing health endpoints..." -ForegroundColor Yellow
try {
    $webHealth = Invoke-RestMethod -Uri "$LOAD_BALANCER_URL/health" -Method Get
    Write-Host "✅ Web service health check passed" -ForegroundColor Green
} catch {
    Write-Host "❌ Web service health check failed" -ForegroundColor Red
}

try {
    $apiHealth = Invoke-RestMethod -Uri "$API_URL/health" -Method Get
    Write-Host "✅ API service health check passed" -ForegroundColor Green
} catch {
    Write-Host "❌ API service health check failed" -ForegroundColor Red
}

Write-Host "✅ Health checks completed" -ForegroundColor Green
```

### **2. Test Image Upload Functionality**

**Bash/Linux/macOS:**

```bash
# Create a test image file
echo "Creating test image..."
curl -o test-image.jpg "https://via.placeholder.com/300x200/09f/fff.png"

# Test image upload
echo "Testing image upload..."
curl -X POST -F "file=@test-image.jpg" $API_URL/images/upload

echo "✅ Image upload test completed"
```

**PowerShell/Windows:**

```powershell
# Create a test image file
Write-Host "Creating test image..." -ForegroundColor Yellow
Invoke-WebRequest -Uri "https://via.placeholder.com/300x200/09f/fff.png" -OutFile "test-image.jpg"

# Test image upload
Write-Host "Testing image upload..." -ForegroundColor Yellow
try {
    $form = @{
        file = Get-Item -Path "test-image.jpg"
    }
    $response = Invoke-RestMethod -Uri "$API_URL/images/upload" -Method Post -Form $form
    Write-Host "✅ Image upload test completed" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Image upload test failed: $($_.Exception.Message)" -ForegroundColor Red
}
```

### **3. Monitor ECS Services**

**Bash/Linux/macOS:**

```bash
# Check ECS service status
aws ecs describe-services \
  --cluster ${ENVIRONMENT_NAME}-cluster \
  --services ${ENVIRONMENT_NAME}-api-service ${ENVIRONMENT_NAME}-web-service \
  --query 'services[].{Name:serviceName,Status:status,Running:runningCount,Desired:desiredCount}' \
  --output table
```

**PowerShell/Windows:**

```powershell
# Check ECS service status
aws ecs describe-services `
  --cluster "$ENVIRONMENT_NAME-cluster" `
  --services "$ENVIRONMENT_NAME-api-service" "$ENVIRONMENT_NAME-web-service" `
  --query 'services[].{Name:serviceName,Status:status,Running:runningCount,Desired:desiredCount}' `
  --output table
```

### **4. View CloudWatch Logs**

**Bash/Linux/macOS:**

```bash
# List recent log streams
aws logs describe-log-streams \
  --log-group-name /ecs/${ENVIRONMENT_NAME} \
  --order-by LastEventTime \
  --descending \
  --max-items 5 \
  --query 'logStreams[].logStreamName'

# View recent logs
aws logs filter-log-events \
  --log-group-name /ecs/${ENVIRONMENT_NAME} \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --query 'events[].message' \
  --output text
```

**PowerShell/Windows:**

```powershell
# List recent log streams
aws logs describe-log-streams `
  --log-group-name "/ecs/$ENVIRONMENT_NAME" `
  --order-by LastEventTime `
  --descending `
  --max-items 5 `
  --query 'logStreams[].logStreamName'

# View recent logs (last hour)
$oneHourAgo = [int][double]::Parse((Get-Date).AddHours(-1).ToString("yyyyMMddHHmmss"))
aws logs filter-log-events `
  --log-group-name "/ecs/$ENVIRONMENT_NAME" `
  --start-time "${oneHourAgo}000" `
  --query 'events[].message' `
  --output text
```

---

## 📊 Monitoring and Management

### **AWS Console Access**

After deployment, you can monitor your application through:

1. **ECS Console**: Navigate to the ECS service in your AWS region to monitor cluster health
2. **CloudFormation Console**: View stack status and outputs
3. **CloudWatch Console**: Access application logs and metrics
4. **S3 Console**: Monitor bucket usage and uploaded images

### **Useful Management Commands**

**Bash/Linux/macOS:**

```bash
# Scale services up or down
aws ecs update-service \
  --cluster ${ENVIRONMENT_NAME}-cluster \
  --service ${ENVIRONMENT_NAME}-api-service \
  --desired-count 4

# Force new deployment (useful for updates)
aws ecs update-service \
  --cluster ${ENVIRONMENT_NAME}-cluster \
  --service ${ENVIRONMENT_NAME}-api-service \
  --force-new-deployment

# View auto scaling activity
aws application-autoscaling describe-scaling-activities \
  --service-namespace ecs \
  --resource-id service/${ENVIRONMENT_NAME}-cluster/${ENVIRONMENT_NAME}-api-service
```

**PowerShell/Windows:**

```powershell
# Scale services up or down
aws ecs update-service `
  --cluster "$ENVIRONMENT_NAME-cluster" `
  --service "$ENVIRONMENT_NAME-api-service" `
  --desired-count 4

# Force new deployment (useful for updates)
aws ecs update-service `
  --cluster "$ENVIRONMENT_NAME-cluster" `
  --service "$ENVIRONMENT_NAME-api-service" `
  --force-new-deployment

# View auto scaling activity
aws application-autoscaling describe-scaling-activities `
  --service-namespace ecs `
  --resource-id "service/$ENVIRONMENT_NAME-cluster/$ENVIRONMENT_NAME-api-service"
```

---

## 📋 Deployment Timeline

| Phase               | Duration           | What's Happening                                |
| ------------------- | ------------------ | ----------------------------------------------- |
| **ECR Setup**       | 1-2 minutes        | Creating container repositories                 |
| **Docker Build**    | 5-8 minutes        | Building .NET applications into containers      |
| **Image Push**      | 2-5 minutes        | Uploading containers to AWS                     |
| **Infrastructure**  | 10-15 minutes      | Creating VPC, ALB, ECS cluster, security groups |
| **Service Startup** | 3-5 minutes        | Starting containers and health checks           |
| **DNS Propagation** | 1-2 minutes        | Load balancer becoming accessible               |
| **Total**           | **~22-37 minutes** | Complete production deployment                  |

---

## 🆘 Troubleshooting

### **Common Issues**

**Docker Build Fails:**

```bash
# Check Docker daemon
docker info

# Clean up Docker resources
docker system prune -f
```

**ECR Push Fails:**

```bash
# Re-authenticate with ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

**CloudFormation Fails:**

**Bash/Linux/macOS:**

```bash
# Check stack events for failures
aws cloudformation describe-stack-events \
  --stack-name ${ENVIRONMENT_NAME}-ecs-stack \
  --region ${AWS_REGION} \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED` || ResourceStatus==`UPDATE_FAILED`].{Time:Timestamp,Resource:LogicalResourceId,Status:ResourceStatus,Reason:ResourceStatusReason}' \
  --output table

# Get all recent events
aws cloudformation describe-stack-events \
  --stack-name ${ENVIRONMENT_NAME}-ecs-stack \
  --region ${AWS_REGION} \
  --query 'StackEvents[0:10].{Time:Timestamp,Status:ResourceStatus,Reason:ResourceStatusReason}' \
  --output table
```

**PowerShell/Windows:**

```powershell
# Check stack events for failures
aws cloudformation describe-stack-events `
  --stack-name "$ENVIRONMENT_NAME-ecs-stack" `
  --region $AWS_REGION `
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED` || ResourceStatus==`UPDATE_FAILED`].{Time:Timestamp,Resource:LogicalResourceId,Status:ResourceStatus,Reason:ResourceStatusReason}' `
  --output table

# Get all recent events
aws cloudformation describe-stack-events `
  --stack-name "$ENVIRONMENT_NAME-ecs-stack" `
  --region $AWS_REGION `
  --query 'StackEvents[0:10].{Time:Timestamp,Status:ResourceStatus,Reason:ResourceStatusReason}' `
  --output table
```

**Services Won't Start:**

```bash
# Check task failures
aws ecs describe-tasks \
  --cluster ${ENVIRONMENT_NAME}-cluster \
  --tasks $(aws ecs list-tasks --cluster ${ENVIRONMENT_NAME}-cluster --query 'taskArns[]' --output text) \
  --query 'tasks[].{TaskArn:taskArn,LastStatus:lastStatus,StoppedReason:stoppedReason}'
```

### **Getting Help**

- **CloudWatch Logs**: Check `/ecs/${ENVIRONMENT_NAME}` log group
- **ECS Console**: Review service events and task definitions
- **CloudFormation Console**: Check stack events and outputs
- **S3 Console**: Verify bucket creation and permissions

---

## 🧹 Cleanup

### **Delete Everything**

**Bash/Linux/macOS:**

```bash
# Delete the entire deployment
aws cloudformation delete-stack --stack-name ${ENVIRONMENT_NAME}-ecs-stack

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete --stack-name ${ENVIRONMENT_NAME}-ecs-stack

# Optionally delete ECR repositories (this will delete all images)
aws ecr delete-repository --repository-name aspire-api --force --region $AWS_REGION
aws ecr delete-repository --repository-name aspire-web --force --region $AWS_REGION

echo "✅ Cleanup completed"
```

**PowerShell/Windows:**

```powershell
# Use the management script (recommended - with confirmation prompt)
.\scripts\manage-deployment.ps1 -Action cleanup -EnvironmentName $ENVIRONMENT_NAME

# Or manual cleanup
aws cloudformation delete-stack --stack-name "$ENVIRONMENT_NAME-ecs-stack"

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete --stack-name "$ENVIRONMENT_NAME-ecs-stack"

# Optionally delete ECR repositories (this will delete all images)
aws ecr delete-repository --repository-name aspire-api --force --region $AWS_REGION
aws ecr delete-repository --repository-name aspire-web --force --region $AWS_REGION

Write-Host "✅ Cleanup completed" -ForegroundColor Green
```

---

## 🔧 PowerShell Management Helper

**Windows users** can use the included PowerShell management script for common post-deployment tasks:

### **Available Actions**

```powershell
# Check application health status
.\scripts\manage-deployment.ps1 -Action health

# Get application URLs and outputs
.\scripts\manage-deployment.ps1 -Action urls

# Check ECS service status
.\scripts\manage-deployment.ps1 -Action status

# Scale services (adjust number of instances)
.\scripts\manage-deployment.ps1 -Action scale -DesiredCount 4

# View recent application logs
.\scripts\manage-deployment.ps1 -Action logs

# Clean up entire deployment (interactive confirmation)
.\scripts\manage-deployment.ps1 -Action cleanup
```

### **Example Usage**

```powershell
# Monitor a staging environment
.\scripts\manage-deployment.ps1 -Action health -EnvironmentName "aspire-staging" -AwsRegion "us-west-2"

# Scale production to handle more traffic
.\scripts\manage-deployment.ps1 -Action scale -EnvironmentName "aspire-prod" -DesiredCount 6

# Get all deployment URLs
.\scripts\manage-deployment.ps1 -Action urls -EnvironmentName "aspire-prod"
```

This helper script provides a convenient way to manage your deployed stack without memorizing AWS CLI commands!

---

## 🎯 Next Steps

After successful deployment:

1. **Set up CI/CD**: Automate deployments with GitHub Actions (see `AWS-DEPLOYMENT.md`)
2. **Add HTTPS**: Configure SSL certificates with ACM
3. **Custom Domain**: Set up Route 53 with your domain
4. **Monitoring**: Set up CloudWatch dashboards and alarms
5. **Security**: Review IAM policies and enable GuardDuty

---

🎉 **Congratulations!** You now have a production-ready .NET Aspire application running on AWS ECS with auto-scaling, load balancing, and monitoring!
