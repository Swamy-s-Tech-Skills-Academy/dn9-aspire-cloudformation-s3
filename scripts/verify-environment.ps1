#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Verify environment setup for .NET Aspire AWS deployment

.DESCRIPTION
    This script checks all prerequisites needed to deploy the .NET Aspire AWS Stack:
    - PowerShell execution policy
    - AWS CLI installation and configuration
    - Docker installation and running status
    - .NET SDK version
    - Project structure

.EXAMPLE
    .\scripts\verify-environment.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to check a prerequisite
function Test-Prerequisite {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$FailureMessage = "Failed",
        [string]$SuccessMessage = "OK"
    )
    
    Write-Host "Checking $Name... " -NoNewline
    try {
        $result = & $Test
        if ($result) {
            Write-ColorOutput "✅ $SuccessMessage" "Green"
            return $true
        }
        else {
            Write-ColorOutput "❌ $FailureMessage" "Red"
            return $false
        }
    }
    catch {
        Write-ColorOutput "❌ $FailureMessage - $($_.Exception.Message)" "Red"
        return $false
    }
}

Write-ColorOutput "🔍 .NET Aspire AWS Deployment - Environment Verification" "Cyan"
Write-ColorOutput "═══════════════════════════════════════════════════════" "Cyan"

$allPassed = $true

# Check PowerShell execution policy
$passed = Test-Prerequisite -Name "PowerShell Execution Policy" -Test {
    $policy = Get-ExecutionPolicy
    return $policy -ne "Restricted"
} -FailureMessage "Execution policy is Restricted" -SuccessMessage "Execution policy allows scripts ($((Get-ExecutionPolicy)))"

if (-not $passed) {
    Write-ColorOutput "   💡 Fix: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" "Yellow"
}
$allPassed = $allPassed -and $passed

# Check PowerShell version
$passed = Test-Prerequisite -Name "PowerShell Version" -Test {
    $version = $PSVersionTable.PSVersion
    return $version.Major -ge 5
} -SuccessMessage "PowerShell $($PSVersionTable.PSVersion)"

$allPassed = $allPassed -and $passed

# Check AWS CLI
$passed = Test-Prerequisite -Name "AWS CLI" -Test {
    $null = aws --version 2>$null
    return $LASTEXITCODE -eq 0
} -FailureMessage "AWS CLI not found" -SuccessMessage "Installed"

if (-not $passed) {
    Write-ColorOutput "   💡 Install: winget install Amazon.AWSCLI" "Yellow"
    Write-ColorOutput "   💡 Or download: https://aws.amazon.com/cli/" "Yellow"
}
$allPassed = $allPassed -and $passed

# Check AWS CLI configuration
if ($passed) {
    $passed = Test-Prerequisite -Name "AWS CLI Configuration" -Test {
        $null = aws sts get-caller-identity 2>$null
        return $LASTEXITCODE -eq 0
    } -FailureMessage "Not configured or no valid credentials" -SuccessMessage "Configured and authenticated"
    
    if ($passed) {
        try {
            $identity = aws sts get-caller-identity --output json | ConvertFrom-Json
            Write-ColorOutput "   Account: $($identity.Account)" "Gray"
            Write-ColorOutput "   User/Role: $($identity.Arn)" "Gray"
        }
        catch {
            # Silent fail
        }
    }
    else {
        Write-ColorOutput "   💡 Configure: aws configure" "Yellow"
    }
    $allPassed = $allPassed -and $passed
}

# Check Docker installation
$passed = Test-Prerequisite -Name "Docker Installation" -Test {
    $null = docker --version 2>$null
    return $LASTEXITCODE -eq 0
} -FailureMessage "Docker not found" -SuccessMessage "Installed"

if (-not $passed) {
    Write-ColorOutput "   💡 Install Docker Desktop: https://www.docker.com/products/docker-desktop/" "Yellow"
}
$allPassed = $allPassed -and $passed

# Check Docker daemon
if ($passed) {
    $passed = Test-Prerequisite -Name "Docker Daemon" -Test {
        $null = docker info 2>$null
        return $LASTEXITCODE -eq 0
    } -FailureMessage "Docker daemon not running" -SuccessMessage "Running"
    
    if (-not $passed) {
        Write-ColorOutput "   💡 Start Docker Desktop application" "Yellow"
    }
    $allPassed = $allPassed -and $passed
}

# Check .NET SDK
$passed = Test-Prerequisite -Name ".NET SDK" -Test {
    $versionString = dotnet --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        # Handle preview versions by extracting just the major.minor.patch part
        # e.g., "10.0.100-preview.5.25277.114" -> "10.0.100"
        $cleanVersion = $versionString -replace '-.*$', ''
        try {
            $versionNum = [version]$cleanVersion
            return $versionNum.Major -ge 8
        }
        catch {
            # If version parsing fails, try simple string comparison
            return $versionString -match '^(8|9|1[0-9])\.'
        }
    }
    return $false
} -FailureMessage ".NET 8+ SDK not found" -SuccessMessage ".NET $(dotnet --version 2>$null)"

if (-not $passed) {
    Write-ColorOutput "   💡 Install: https://dotnet.microsoft.com/download" "Yellow"
}
$allPassed = $allPassed -and $passed

# Check project structure
$passed = Test-Prerequisite -Name "Project Structure" -Test {
    return (Test-Path "src/AspireAwsStack.AppHost") -and 
           (Test-Path "src/AspireAwsStack.ApiService") -and 
           (Test-Path "src/AspireAwsStack.Web") -and
           (Test-Path "scripts/deploy-to-aws.ps1")
} -FailureMessage "Missing required project files" -SuccessMessage "All required files present"

$allPassed = $allPassed -and $passed

# Check CloudFormation template
$passed = Test-Prerequisite -Name "CloudFormation Template" -Test {
    return Test-Path "src/AspireAwsStack.AppHost/infrastructure/ecs-complete-stack.yaml"
} -FailureMessage "CloudFormation template not found" -SuccessMessage "Template found"

$allPassed = $allPassed -and $passed

Write-Host ""
Write-ColorOutput "═══════════════════════════════════════════════════════" "Cyan"

if ($allPassed) {
    Write-ColorOutput "🎉 All prerequisites verified! You're ready to deploy." "Green"
    Write-Host ""
    Write-ColorOutput "Next steps:" "Cyan"
    Write-ColorOutput "1. Deploy: .\scripts\deploy-to-aws.ps1" "White"
    Write-ColorOutput "2. Monitor: .\scripts\manage-deployment.ps1 -Action health" "White"
    Write-ColorOutput "3. Scale: .\scripts\manage-deployment.ps1 -Action scale -DesiredCount 4" "White"
}
else {
    Write-ColorOutput "❌ Some prerequisites are missing. Please fix the issues above." "Red"
    Write-Host ""
    Write-ColorOutput "For detailed setup instructions, see:" "Yellow"
    Write-ColorOutput "- docs/POWERSHELL-QUICKSTART.md" "White"
    Write-ColorOutput "- docs/DEPLOYMENT-GUIDE.md" "White"
}

Write-Host ""
