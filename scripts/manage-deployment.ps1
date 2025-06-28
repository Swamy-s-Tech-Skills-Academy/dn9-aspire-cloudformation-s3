#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Helper script for managing deployed AWS Aspire stack

.DESCRIPTION
    This script provides common management tasks for the deployed AWS Aspire stack,
    including health checks, scaling, log viewing, and cleanup operations.

.PARAMETER EnvironmentName
    The environment name used during deployment (default: aspire-prod)

.PARAMETER AwsRegion
    The AWS region where resources are deployed (default: us-east-1)

.PARAMETER Action
    The action to perform: health, scale, logs, urls, cleanup

.PARAMETER DesiredCount
    For scale action: desired number of service instances

.EXAMPLE
    .\scripts\manage-deployment.ps1 -Action health
    
.EXAMPLE
    .\scripts\manage-deployment.ps1 -Action scale -DesiredCount 4

.EXAMPLE
    .\scripts\manage-deployment.ps1 -Action logs -EnvironmentName "aspire-staging"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("health", "scale", "logs", "urls", "cleanup", "status")]
    [string]$Action,
    
    [string]$EnvironmentName = "aspire-prod",
    [string]$AwsRegion = "us-east-1",
    [int]$DesiredCount = 2
)

$ErrorActionPreference = "Stop"

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Configuration
$StackName = "$EnvironmentName-ecs-stack"
$ClusterName = "$EnvironmentName-cluster"
$ApiServiceName = "$EnvironmentName-api-service"
$WebServiceName = "$EnvironmentName-web-service"

Write-ColorOutput "🔧 Managing AWS Aspire Stack" "Green"
Write-ColorOutput "Environment: $EnvironmentName" "Cyan"
Write-ColorOutput "Region: $AwsRegion" "Cyan"
Write-ColorOutput "Action: $Action" "Yellow"

switch ($Action) {
    "health" {
        Write-ColorOutput "🔍 Checking application health..." "Yellow"
        
        try {
            # Get stack outputs
            $outputs = aws cloudformation describe-stacks `
                --stack-name $StackName `
                --query 'Stacks[0].Outputs' `
                --output json `
                --region $AwsRegion | ConvertFrom-Json
            
            $loadBalancerUrl = ($outputs | Where-Object { $_.OutputKey -eq "LoadBalancerUrl" }).OutputValue
            $apiUrl = ($outputs | Where-Object { $_.OutputKey -eq "ApiUrl" }).OutputValue
            
            # Test health endpoints
            try {
                $webHealth = Invoke-RestMethod -Uri "$loadBalancerUrl/health" -Method Get -TimeoutSec 10
                Write-ColorOutput "✅ Web service health: OK" "Green"
            }
            catch {
                Write-ColorOutput "❌ Web service health: FAILED" "Red"
            }
            
            try {
                $apiHealth = Invoke-RestMethod -Uri "$apiUrl/health" -Method Get -TimeoutSec 10
                Write-ColorOutput "✅ API service health: OK" "Green"
            }
            catch {
                Write-ColorOutput "❌ API service health: FAILED" "Red"
            }
            
        }
        catch {
            Write-ColorOutput "❌ Failed to get stack outputs: $($_.Exception.Message)" "Red"
        }
    }
    
    "scale" {
        Write-ColorOutput "📈 Scaling services to $DesiredCount instances..." "Yellow"
        
        # Scale API service
        aws ecs update-service `
            --cluster $ClusterName `
            --service $ApiServiceName `
            --desired-count $DesiredCount `
            --region $AwsRegion
        
        # Scale Web service
        aws ecs update-service `
            --cluster $ClusterName `
            --service $WebServiceName `
            --desired-count $DesiredCount `
            --region $AwsRegion
        
        Write-ColorOutput "✅ Scaling initiated. Services will scale to $DesiredCount instances." "Green"
    }
    
    "logs" {
        Write-ColorOutput "📋 Fetching recent logs..." "Yellow"
        
        $logGroupName = "/ecs/$EnvironmentName"
        $oneHourAgo = [int][double]::Parse((Get-Date).AddHours(-1).ToString("yyyyMMddHHmmss"))
        
        Write-ColorOutput "Recent logs from $logGroupName:" "Cyan"
        aws logs filter-log-events `
            --log-group-name $logGroupName `
            --start-time "${oneHourAgo}000" `
            --query 'events[].[timestamp,message]' `
            --output table `
            --region $AwsRegion
    }
    
    "urls" {
        Write-ColorOutput "🌐 Getting application URLs..." "Yellow"
        
        try {
            $outputs = aws cloudformation describe-stacks `
                --stack-name $StackName `
                --query 'Stacks[0].Outputs' `
                --output json `
                --region $AwsRegion | ConvertFrom-Json
            
            Write-ColorOutput "📋 Application URLs:" "Cyan"
            foreach ($output in $outputs) {
                Write-ColorOutput "├── $($output.OutputKey): $($output.OutputValue)" "White"
            }
            
        }
        catch {
            Write-ColorOutput "❌ Failed to get stack outputs: $($_.Exception.Message)" "Red"
        }
    }
    
    "status" {
        Write-ColorOutput "📊 Getting service status..." "Yellow"
        
        aws ecs describe-services `
            --cluster $ClusterName `
            --services $ApiServiceName $WebServiceName `
            --query 'services[].{Name:serviceName,Status:status,Running:runningCount,Desired:desiredCount,Health:healthCheckGracePeriodSeconds}' `
            --output table `
            --region $AwsRegion
    }
    
    "cleanup" {
        Write-ColorOutput "🧹 Cleaning up deployment..." "Yellow"
        
        $confirmation = Read-Host "Are you sure you want to delete the entire stack? This cannot be undone. Type 'yes' to confirm"
        
        if ($confirmation -eq "yes") {
            Write-ColorOutput "Deleting CloudFormation stack..." "Red"
            
            aws cloudformation delete-stack `
                --stack-name $StackName `
                --region $AwsRegion
            
            Write-ColorOutput "✅ Stack deletion initiated. This may take 10-15 minutes." "Green"
            Write-ColorOutput "Monitor progress in the AWS CloudFormation console." "Yellow"
        }
        else {
            Write-ColorOutput "❌ Cleanup cancelled." "Yellow"
        }
    }
}

Write-ColorOutput "🚀 Management operation completed!" "Green"
