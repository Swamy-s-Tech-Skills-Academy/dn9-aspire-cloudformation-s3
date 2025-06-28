#!/bin/bash
set -e

# Configuration
ENVIRONMENT_NAME=${1:-aspire-prod}
AWS_REGION=${2:-us-east-1}
STACK_NAME="${ENVIRONMENT_NAME}-ecs-stack"

echo "🚀 Starting deployment to AWS ECS..."
echo "Environment: $ENVIRONMENT_NAME"
echo "Region: $AWS_REGION"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account: $AWS_ACCOUNT_ID"

# Generate unique S3 bucket name
S3_BUCKET_NAME="aspire-aws-images-${ENVIRONMENT_NAME}-$(date +%s)"
echo "S3 Bucket: $S3_BUCKET_NAME"

# Step 1: Create ECR repositories if they don't exist
echo "📦 Creating ECR repositories..."
aws ecr describe-repositories --repository-names aspire-api --region $AWS_REGION 2>/dev/null || \
  aws ecr create-repository --repository-name aspire-api --region $AWS_REGION

aws ecr describe-repositories --repository-names aspire-web --region $AWS_REGION 2>/dev/null || \
  aws ecr create-repository --repository-name aspire-web --region $AWS_REGION

# Step 2: Build and push Docker images
echo "🐳 Building and pushing Docker images..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build images
docker build -f src/AspireAwsStack.ApiService/Dockerfile -t aspire-api .
docker build -f src/AspireAwsStack.Web/Dockerfile -t aspire-web .

# Tag and push
docker tag aspire-api:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aspire-api:latest
docker tag aspire-web:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aspire-web:latest

docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aspire-api:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aspire-web:latest

# Step 3: Deploy CloudFormation stack
echo "☁️ Deploying CloudFormation stack..."
aws cloudformation deploy \
  --template-file src/AspireAwsStack.AppHost/infrastructure/ecs-complete-stack.yaml \
  --stack-name $STACK_NAME \
  --parameter-overrides \
    EnvironmentName=$ENVIRONMENT_NAME \
    ApiImageUri=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aspire-api:latest \
    WebImageUri=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aspire-web:latest \
    S3BucketName=$S3_BUCKET_NAME \
    MinCapacity=2 \
    MaxCapacity=10 \
    TaskCpu=512 \
    TaskMemory=1024 \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $AWS_REGION

# Step 4: Get outputs
echo "✅ Deployment completed! Getting outputs..."
LOAD_BALANCER_URL=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerUrl`].OutputValue' \
  --output text \
  --region $AWS_REGION)

API_URL=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiUrl`].OutputValue' \
  --output text \
  --region $AWS_REGION)

S3_URL=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query 'Stacks[0].Outputs[?OutputKey==`S3BucketUrl`].OutputValue' \
  --output text \
  --region $AWS_REGION)

echo ""
echo "🎉 Deployment successful!"
echo "🌐 Application URL: $LOAD_BALANCER_URL"
echo "🔗 API URL: $API_URL"
echo "📦 S3 Bucket: $S3_URL"
echo ""
echo "Wait 5-10 minutes for services to fully start up, then visit the application URL."
