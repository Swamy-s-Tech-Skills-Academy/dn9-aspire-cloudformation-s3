#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy .NET Aspire AWS Stack to AWS ECS using CloudFormation

.DESCRIPTION
    This script automates the deployment of the .NET Aspire AWS Stack to AWS ECS.
    It creates ECR repositories, builds and pushes Docker images, and deploys the
    complete infrastructure using CloudFormation.

.PARAMETER EnvironmentName
    The environment name prefix for AWS resources (default: aspire-prod)

.PARAMETER AwsRegion
    The target AWS region (default: us-east-1)

.PARAMETER MinCapacity
    Minimum number of ECS tasks (default: 2)

.PARAMETER MaxCapacity
    Maximum number of ECS tasks (default: 10)

.PARAMETER TaskCpu
    CPU units for ECS tasks (default: 512)

.PARAMETER TaskMemory
    Memory (MB) for ECS tasks (default: 1024)

.EXAMPLE
    .\scripts\deploy-to-aws.ps1 -EnvironmentName "aspire-prod" -AwsRegion "us-east-1"

.EXAMPLE
    .\scripts\deploy-to-aws.ps1 "aspire-staging" "us-west-2"
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$EnvironmentName = "aspire-prod",
    
    [Parameter(Position = 1)]
    [string]$AwsRegion = "us-east-1",
    
    [int]$MinCapacity = 2,
    [int]$MaxCapacity = 10,
    [int]$TaskCpu = 512,
    [int]$TaskMemory = 1024
)

# Set error action preference to stop on errors
$ErrorActionPreference = "Stop"

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to execute AWS CLI commands with error handling
function Invoke-AwsCommand {
    param(
        [string]$Command,
        [string]$Description
    )
    
    Write-ColorOutput "Executing: $Description" "Yellow"
    Write-ColorOutput "Command: $Command" "Gray"
    
    try {
        $result = Invoke-Expression $Command
        return $result
    }
    catch {
        Write-ColorOutput "❌ Failed: $Description" "Red"
        Write-ColorOutput "Error: $($_.Exception.Message)" "Red"
        throw
    }
}

# Configuration
$StackName = "$EnvironmentName-ecs-stack"

Write-ColorOutput "🚀 Starting deployment to AWS ECS..." "Green"
Write-ColorOutput "Environment: $EnvironmentName" "Cyan"
Write-ColorOutput "Region: $AwsRegion" "Cyan"
Write-ColorOutput "Stack Name: $StackName" "Cyan"

# Get AWS Account ID
Write-ColorOutput "🔍 Getting AWS Account information..." "Yellow"
try {
    $AwsAccountId = aws sts get-caller-identity --query Account --output text
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get AWS account ID. Please check your AWS CLI configuration."
    }
    Write-ColorOutput "AWS Account: $AwsAccountId" "Green"
}
catch {
    Write-ColorOutput "❌ Failed to get AWS account information" "Red"
    Write-ColorOutput "Please ensure AWS CLI is configured with valid credentials" "Red"
    exit 1
}

# Generate unique S3 bucket name
$Timestamp = [int][double]::Parse((Get-Date -UFormat %s))
$S3BucketName = "aspire-aws-images-$EnvironmentName-$Timestamp"
Write-ColorOutput "S3 Bucket: $S3BucketName" "Cyan"

# Step 1: Create ECR repositories if they don't exist
Write-ColorOutput "📦 Creating ECR repositories..." "Yellow"

# Function to ensure ECR repository exists
function Test-AndCreateEcrRepository {
    param([string]$RepositoryName)
    
    Write-ColorOutput "Checking repository: $RepositoryName" "Gray"
    
    # Check if repository exists
    aws ecr describe-repositories --repository-names $RepositoryName --region $AwsRegion 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ $RepositoryName repository already exists" "Green"
        return $true
    }
    
    # Repository doesn't exist, create it
    Write-ColorOutput "Creating $RepositoryName repository..." "Yellow"
    aws ecr create-repository --repository-name $RepositoryName --region $AwsRegion
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ $RepositoryName repository created successfully" "Green"
        return $true
    } else {
        Write-ColorOutput "❌ Failed to create $RepositoryName repository" "Red"
        return $false
    }
}

# Ensure both repositories exist
if (-not (Test-AndCreateEcrRepository "aspire-api")) {
    throw "Failed to create or verify aspire-api repository"
}

if (-not (Test-AndCreateEcrRepository "aspire-web")) {
    throw "Failed to create or verify aspire-web repository"
}

# Step 2: Build and push Docker images
Write-ColorOutput "🐳 Building and pushing Docker images..." "Yellow"

# Login to ECR
Write-ColorOutput "Logging into ECR..." "Yellow"
$loginCommand = "aws ecr get-login-password --region $AwsRegion | docker login --username AWS --password-stdin $AwsAccountId.dkr.ecr.$AwsRegion.amazonaws.com"
Invoke-Expression $loginCommand
if ($LASTEXITCODE -ne 0) {
    throw "Failed to login to ECR"
}

# Build images
Write-ColorOutput "Building Docker images..." "Yellow"
docker build -f src/AspireAwsStack.ApiService/Dockerfile -t aspire-api .
if ($LASTEXITCODE -ne 0) {
    throw "Failed to build aspire-api Docker image"
}

docker build -f src/AspireAwsStack.Web/Dockerfile -t aspire-web .
if ($LASTEXITCODE -ne 0) {
    throw "Failed to build aspire-web Docker image"
}

# Tag and push images
Write-ColorOutput "Tagging and pushing images..." "Yellow"
$ApiImageUri = "$AwsAccountId.dkr.ecr.$AwsRegion.amazonaws.com/aspire-api:latest"
$WebImageUri = "$AwsAccountId.dkr.ecr.$AwsRegion.amazonaws.com/aspire-web:latest"

docker tag aspire-api:latest $ApiImageUri
docker tag aspire-web:latest $WebImageUri

# Verify repositories exist before pushing
Write-ColorOutput "Verifying ECR repositories before push..." "Yellow"
aws ecr describe-repositories --repository-names aspire-api aspire-web --region $AwsRegion --query 'repositories[].repositoryName' --output table

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "❌ ECR repositories verification failed" "Red"
    throw "ECR repositories not found. Please check repository creation."
}

docker push $ApiImageUri
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "❌ Failed to push aspire-api image. Repository URI: $ApiImageUri" "Red"
    throw "Failed to push aspire-api image"
}

docker push $WebImageUri
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "❌ Failed to push aspire-web image. Repository URI: $WebImageUri" "Red"
    throw "Failed to push aspire-web image"
}

Write-ColorOutput "✅ Docker images built and pushed successfully" "Green"

# Step 3: Deploy CloudFormation stack
Write-ColorOutput "☁️ Deploying CloudFormation stack..." "Yellow"

$deployCommand = @"
aws cloudformation deploy ``
  --template-file src/AspireAwsStack.AppHost/infrastructure/ecs-complete-stack.yaml ``
  --stack-name $StackName ``
  --parameter-overrides ``
    EnvironmentName=$EnvironmentName ``
    ApiImageUri=$ApiImageUri ``
    WebImageUri=$WebImageUri ``
    S3BucketName=$S3BucketName ``
    MinCapacity=$MinCapacity ``
    MaxCapacity=$MaxCapacity ``
    TaskCpu=$TaskCpu ``
    TaskMemory=$TaskMemory ``
  --capabilities CAPABILITY_NAMED_IAM ``
  --region $AwsRegion
"@

Invoke-Expression $deployCommand
if ($LASTEXITCODE -ne 0) {
    throw "Failed to deploy CloudFormation stack"
}

Write-ColorOutput "✅ CloudFormation stack deployed successfully" "Green"

# Step 4: Get outputs
Write-ColorOutput "✅ Deployment completed! Getting outputs..." "Yellow"

try {
    $LoadBalancerUrl = aws cloudformation describe-stacks `
        --stack-name $StackName `
        --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerUrl`].OutputValue' `
        --output text `
        --region $AwsRegion

    $ApiUrl = aws cloudformation describe-stacks `
        --stack-name $StackName `
        --query 'Stacks[0].Outputs[?OutputKey==`ApiUrl`].OutputValue' `
        --output text `
        --region $AwsRegion

    $S3Url = aws cloudformation describe-stacks `
        --stack-name $StackName `
        --query 'Stacks[0].Outputs[?OutputKey==`S3BucketUrl`].OutputValue' `
        --output text `
        --region $AwsRegion

    Write-Host ""
    Write-ColorOutput "🎉 Deployment successful!" "Green"
    Write-Host ""
    Write-ColorOutput "📋 Deployment Summary:" "Cyan"
    Write-ColorOutput "├── 🌐 Application URL: $LoadBalancerUrl" "White"
    Write-ColorOutput "├── 🔗 API URL: $ApiUrl" "White"
    Write-ColorOutput "├── 📦 S3 Bucket: $S3Url" "White"
    Write-ColorOutput "├── 🏷️  Environment: $EnvironmentName" "White"
    Write-ColorOutput "└── 🌍 Region: $AwsRegion" "White"
    Write-Host ""
    Write-ColorOutput "⏱️  Wait 5-10 minutes for services to fully start up, then visit the application URL." "Yellow"
    Write-Host ""
    
    # Save outputs to a file for reference
    $outputFile = "deployment-outputs-$EnvironmentName.txt"
    @"
Deployment completed at: $(Get-Date)
Environment: $EnvironmentName
Region: $AwsRegion
Stack Name: $StackName

Application URL: $LoadBalancerUrl
API URL: $ApiUrl
S3 Bucket URL: $S3Url
S3 Bucket Name: $S3BucketName

API Image URI: $ApiImageUri
Web Image URI: $WebImageUri
"@ | Out-File -FilePath $outputFile -Encoding UTF8
    
    Write-ColorOutput "📄 Deployment details saved to: $outputFile" "Cyan"
}
catch {
    Write-ColorOutput "⚠️  Deployment may have succeeded, but failed to retrieve outputs" "Yellow"
    Write-ColorOutput "Check the AWS CloudFormation console for stack outputs" "Yellow"
}

Write-ColorOutput "🚀 Deployment script completed!" "Green"
