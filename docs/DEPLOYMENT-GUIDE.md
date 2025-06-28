# 🚀 Quick Deployment Guide

This guide provides step-by-step instructions for deploying your .NET Aspire AWS Stack to production using AWS ECS.

## 🎯 Prerequisites

Before you begin, ensure you have:

- ✅ AWS CLI installed and configured with appropriate permissions
- ✅ Docker installed and running
- ✅ Access to an AWS account with ECS, ECR, CloudFormation, and S3 permissions
- ✅ The project cloned and built locally

### **Verify Prerequisites**

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

---

## 🚀 Option 1: One-Command Deployment (Recommended)

### **Step 1: Make Script Executable**

```bash
chmod +x scripts/deploy-to-aws.sh
```

### **Step 2: Deploy Everything**

```bash
# Deploy to production environment
./scripts/deploy-to-aws.sh aspire-prod us-east-1

# Or deploy to staging environment
./scripts/deploy-to-aws.sh aspire-staging us-west-2
```

### **Script Parameters**

| Parameter        | Description                  | Default       | Example          |
| ---------------- | ---------------------------- | ------------- | ---------------- |
| Environment Name | Prefix for all AWS resources | `aspire-prod` | `aspire-staging` |
| AWS Region       | Target AWS region            | `us-east-1`   | `us-west-2`      |

### **What the Script Does**

1. 📦 **Creates ECR repositories** (if they don't exist)
2. 🐳 **Builds Docker images** for API and Web services
3. ⬆️ **Pushes images to ECR** with proper tagging
4. ☁️ **Deploys CloudFormation stack** with complete infrastructure
5. 📋 **Outputs deployment results** with URLs and endpoints

---

## 🔧 Option 2: Manual Step-by-Step Deployment

If you prefer more control over each step:

### **Step 1: Set Environment Variables**

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

### **Step 2: Create ECR Repositories**

```bash
# Create repositories for container images
aws ecr create-repository --repository-name aspire-api --region $AWS_REGION
aws ecr create-repository --repository-name aspire-web --region $AWS_REGION

# Verify repositories were created
aws ecr describe-repositories --region $AWS_REGION --query 'repositories[].repositoryName'
```

### **Step 3: Build and Push Docker Images**

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

### **Step 4: Deploy CloudFormation Stack**

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

echo "✅ CloudFormation deployment initiated!"
```

### **Step 5: Get Deployment Outputs**

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
echo "🎉 Deployment completed successfully!"
echo "🌐 Application URL: $LOAD_BALANCER_URL"
echo "🔗 API URL: $API_URL"
echo "📦 S3 Bucket: $S3_URL"
```

---

## 🔍 Post-Deployment Verification

### **1. Check Application Health**

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

### **2. Test Image Upload Functionality**

```bash
# Create a test image file
echo "Creating test image..."
curl -o test-image.jpg "https://via.placeholder.com/300x200/09f/fff.png"

# Test image upload
echo "Testing image upload..."
curl -X POST -F "file=@test-image.jpg" $API_URL/images/upload

echo "✅ Image upload test completed"
```

### **3. Monitor ECS Services**

```bash
# Check ECS service status
aws ecs describe-services \
  --cluster ${ENVIRONMENT_NAME}-cluster \
  --services ${ENVIRONMENT_NAME}-api-service ${ENVIRONMENT_NAME}-web-service \
  --query 'services[].{Name:serviceName,Status:status,Running:runningCount,Desired:desiredCount}' \
  --output table
```

### **4. View CloudWatch Logs**

```bash
# List recent log streams
aws logs describe-log-streams \
  --log-group-name /ecs/${ENVIRONMENT_NAME} \
  --order-by LastEventTime \
  --descending \
  --max-items 10 \
  --query 'logStreams[].{Name:logStreamName,LastEvent:lastEventTime}' \
  --output table

# View recent API logs
aws logs get-log-events \
  --log-group-name /ecs/${ENVIRONMENT_NAME} \
  --log-stream-name "api/api-service/$(aws logs describe-log-streams --log-group-name /ecs/${ENVIRONMENT_NAME} --query 'logStreams[?contains(logStreamName, `api`)].logStreamName' --output text | head -1)" \
  --limit 20 \
  --query 'events[].message' \
  --output text
```

---

## 📊 Monitoring and Management

### **AWS Console Access**

After deployment, you can monitor your application through:

1. **ECS Console**: `https://console.aws.amazon.com/ecs/home?region=${AWS_REGION}#/clusters/${ENVIRONMENT_NAME}-cluster`
2. **CloudFormation Console**: `https://console.aws.amazon.com/cloudformation/home?region=${AWS_REGION}#/stacks/stackinfo?stackId=${ENVIRONMENT_NAME}-ecs-stack`
3. **CloudWatch Console**: `https://console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#logsV2:log-groups/log-group/%2Fecs%2F${ENVIRONMENT_NAME}`
4. **S3 Console**: `https://console.aws.amazon.com/s3/buckets/${S3_BUCKET_NAME}`

### **Useful Commands**

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

```bash
# Check stack events
aws cloudformation describe-stack-events \
  --stack-name ${ENVIRONMENT_NAME}-ecs-stack \
  --query 'StackEvents[0:10].{Time:Timestamp,Status:ResourceStatus,Reason:ResourceStatusReason}' \
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
