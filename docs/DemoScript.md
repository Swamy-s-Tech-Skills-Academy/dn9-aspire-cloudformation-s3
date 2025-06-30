# 🎯 .NET Aspire Local Development Demo Script

**Demo Duration:** 5-7 minutes  
**Audience:** Technical stakeholders, developers, architects  
**Goal:** Showcase .NET Aspire local development experience with microservices orchestration

---

## 🎬 Demo Setup (Before Starting)

**Pre-demo checklist:**

- [ ] .NET 9 SDK installed
- [ ] Docker Desktop is running
- [ ] Visual Studio or VS Code ready
- [ ] Terminal/PowerShell ready
- [ ] Project cloned and ready

```powershell
# Quick verification (30 seconds)
.\scripts\verify-environment.ps1
```

---

## 🚀 Demo Script (6 minutes)

### **Opening (30 seconds)**

_"Good morning! Today I'll demonstrate the local development experience with .NET Aspire - Microsoft's new orchestration framework for microservices. We'll see how Aspire simplifies running multiple services, provides monitoring, and streamlines the development workflow."_

### **1. Project Overview (1 minute)**

```bash
# Show project structure
Get-ChildItem -Recurse -Depth 2 | Select-Object Name, Mode | Format-Table
```

_"This is a .NET 9 Aspire solution with:"_

- ✅ **Blazor Web UI** - Modern responsive interface for image uploads
- ✅ **RESTful API** - Image processing with OpenAPI documentation
- ✅ **Local S3 Simulation** - MinIO or local file storage simulation
- ✅ **Service Orchestration** - Aspire coordinates multiple services
- ✅ **Hot Reload & Monitoring** - Real-time development experience

### **2. Aspire Development Experience (3 minutes)**

```powershell
# Start Aspire locally
cd src/AspireAwsStack.AppHost
dotnet run
```

_"Let's explore what Aspire gives us out of the box:"_

**Aspire Dashboard Features:**
- 🎯 **Service Overview** - All services in one view
- 📊 **Real-time Metrics** - CPU, memory, request rates
- 📋 **Structured Logs** - Centralized logging across services
- 🔄 **Service Dependencies** - Visual service map
- 🌡️ **Health Checks** - Service status monitoring
- 🔍 **Tracing** - Request flow across services

**[Navigate through dashboard while explaining]**

### **3. Live Application Demo (1.5 minutes)**

**[Open browser to local application URL shown in dashboard]**

_"Here's our application running locally with Aspire orchestration:"_

1. **Navigate to /images** - Show the upload interface
2. **Upload a sample image** - Demonstrate local file handling
3. **Show the gallery** - Images stored locally
4. **Open /scalar/v1** - API documentation interface
5. **Test API endpoint** - Show RESTful API functionality

### **4. Development Workflow Magic (1 minute)**

**[Make a code change to demonstrate hot reload]**

```csharp
// In Blazor component - change UI text or add a feature
// Watch Aspire automatically rebuild and refresh
```

_"Key development benefits with Aspire:"_

- 🔥 **Hot Reload** - Changes reflect immediately
- 🔄 **Automatic Restarts** - Services restart when needed
- 📱 **Multi-service Debugging** - Debug across service boundaries
- 🎯 **Consistent Environment** - Same experience for all developers
- 🚀 **Fast Feedback Loop** - See changes in seconds

### **5. Service Architecture Overview (30 seconds)**

**[Show in Aspire dashboard]**

_"Our microservices architecture:"_

- **Web Service** - Blazor Server UI (Port 5000)
- **API Service** - RESTful backend (Port 5001)
- **Service Discovery** - Aspire handles inter-service communication
- **Configuration** - Centralized app settings management

### **Closing (30 seconds)**

_"In 5 minutes, we explored the local development experience with .NET Aspire:"_

- ✅ **Simplified Orchestration** - Multiple services, one command
- ✅ **Enhanced Productivity** - Hot reload, debugging, monitoring
- ✅ **Real-time Insights** - Dashboard, logs, metrics, tracing
- ✅ **Team Consistency** - Same environment for every developer
- ✅ **Cloud-Ready Architecture** - Built for modern microservices

_"When ready for production, this same solution deploys seamlessly to cloud platforms like Azure or AWS with minimal configuration changes."_

---

## 🎯 Demo Tips

### **If Application Takes Time to Start:**

- Show the Aspire dashboard loading process
- Explain service dependency resolution
- Demonstrate the project structure while services initialize
- Use the time to show Visual Studio/VS Code integration

### **Backup Demos (if needed):**

```powershell
# Show project structure
Get-ChildItem src\ -Recurse -Name "*.csproj" | Format-Table

# Demonstrate environment verification
.\scripts\verify-environment.ps1

# Show Dockerfile contents for containerization readiness
Get-Content src\AspireAwsStack.ApiService\Dockerfile
```

### **Key Messages:**

1. **"Modern microservices made simple"** - Emphasize developer experience
2. **"One command, full stack"** - Highlight ease of local development
3. **"Built-in observability"** - Real-time monitoring and debugging
4. **"Cloud-ready architecture"** - Production deployment ready

### **Q&A Preparation:**

**Q: How does Aspire compare to Docker Compose?**  
_A: Aspire provides .NET-native orchestration with built-in monitoring, service discovery, and configuration management - more than just container orchestration_

**Q: Can this work with non-.NET services?**  
_A: Yes! Aspire can orchestrate any containerized service alongside .NET services_

**Q: What about production deployment?**  
_A: Aspire projects can deploy to Azure Container Apps, Kubernetes, or any container platform with minimal configuration_

**Q: How does team collaboration work?**  
_A: Every developer gets the same experience - same services, same configuration, same monitoring dashboard_

---

## 🧹 Post-Demo Cleanup

```powershell
# Stop Aspire services
# Ctrl+C in the terminal running dotnet run
```

_Simply stop the dotnet run process - no cloud resources to clean up!_

---

## 📱 Demo Assets

**Have these ready:**

- Sample images for upload testing
- Visual Studio or VS Code open to the project
- PowerShell terminal prepared
- Browser ready for localhost navigation
- Aspire dashboard bookmarked (typically https://localhost:15888)

**Success Metrics:**

- ✅ Aspire services started successfully
- ✅ Dashboard accessible and showing services
- ✅ Image upload working locally
- ✅ Hot reload demonstrated
- ✅ Service orchestration benefits conveyed

---

Good luck with your local development demo! 🚀
