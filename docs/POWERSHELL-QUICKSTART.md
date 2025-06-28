# 🚀 PowerShell Quick Start

**Windows users** - this guide is specifically for you! Follow these steps to deploy your .NET Aspire AWS Stack using PowerShell.

## ⚡ Prerequisites

Run this PowerShell command to verify all prerequisites:

```powershell
# Check PowerShell execution policy
Get-ExecutionPolicy
# If restricted, run: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Check AWS CLI
aws --version
aws sts get-caller-identity

# Check Docker
docker --version
docker info

# Check .NET
dotnet --version

Write-Host "✅ All prerequisites checked!" -ForegroundColor Green
```

## 🎯 One-Command Deployment

Deploy everything to AWS with a single command:

```powershell
# Deploy to production (us-east-1)
.\scripts\deploy-to-aws.ps1

# Deploy to staging with custom region
.\scripts\deploy-to-aws.ps1 -EnvironmentName "aspire-staging" -AwsRegion "us-west-2"

# Deploy with custom scaling parameters
.\scripts\deploy-to-aws.ps1 -EnvironmentName "aspire-prod" -MinCapacity 1 -MaxCapacity 5
```

## 🔧 Post-Deployment Management

After deployment, use the management helper:

```powershell
# Check if your application is healthy
.\scripts\manage-deployment.ps1 -Action health

# Get all application URLs
.\scripts\manage-deployment.ps1 -Action urls

# Scale your application
.\scripts\manage-deployment.ps1 -Action scale -DesiredCount 4

# View recent logs
.\scripts\manage-deployment.ps1 -Action logs

# Clean up everything when done
.\scripts\manage-deployment.ps1 -Action cleanup
```

## 🌐 Access Your Application

After deployment completes (5-10 minutes), you'll see output like:

```text
🎉 Deployment successful!
🌐 Application URL: https://aspire-prod-alb-xxxxxxxxx.us-east-1.elb.amazonaws.com
🔗 API URL: https://aspire-prod-alb-xxxxxxxxx.us-east-1.elb.amazonaws.com/api
📦 S3 Bucket: https://aspire-aws-images-aspire-prod-xxxxxxxxx.s3.amazonaws.com
```

Visit the **Application URL** to start uploading images!

## 🎯 Common PowerShell Commands

### Quick Health Check

```powershell
$urls = .\scripts\manage-deployment.ps1 -Action urls
Invoke-RestMethod -Uri "$($urls.ApplicationUrl)/health"
```

### Scale for Traffic

```powershell
# Scale up for high traffic
.\scripts\manage-deployment.ps1 -Action scale -DesiredCount 6

# Scale down to save costs
.\scripts\manage-deployment.ps1 -Action scale -DesiredCount 2
```

### Monitor Logs

```powershell
# View recent logs
.\scripts\manage-deployment.ps1 -Action logs

# Follow logs in real-time (using AWS CLI directly)
aws logs tail /ecs/aspire-prod --follow
```

## 🧹 Cleanup

When you're done testing:

```powershell
# Interactive cleanup with confirmation
.\scripts\manage-deployment.ps1 -Action cleanup

# This will ask for confirmation before deleting your entire AWS stack
```

## 🆘 Troubleshooting

### Execution Policy Issues

```powershell
# If you get execution policy errors:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### AWS CLI Not Found

```powershell
# Install AWS CLI using winget (Windows 10/11)
winget install Amazon.AWSCLI

# Or download from: https://aws.amazon.com/cli/
```

### Docker Issues

```powershell
# Check if Docker Desktop is running
docker version
# If not working, start Docker Desktop application
```

### PowerShell Version

```powershell
# Check PowerShell version (needs 5.1+ or PowerShell 7+)
$PSVersionTable.PSVersion

# To install PowerShell 7: https://github.com/PowerShell/PowerShell/releases
```

---

**That's it!** Your .NET Aspire application should now be running on AWS ECS. The deployment typically takes 20-30 minutes total.

For more detailed information, see the [complete deployment guide](DEPLOYMENT-GUIDE.md).
