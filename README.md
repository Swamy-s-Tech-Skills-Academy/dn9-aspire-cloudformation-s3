# .NET 9 Aspire CloudFormation S3 - Image Upload Demo

🌩️ A comprehensive .NET 9 Aspire demo showcasing image upload functionality with AWS CloudFormation and Amazon S3 integration. Learn to build scalable cloud-native applications with infrastructure as code.

## 🚀 Overview

This hands-on demo demonstrates how to build a complete image upload solution using .NET 9 Aspire, featuring:

### **✅ Implemented Features**

- 📤 **Image Upload API** - RESTful endpoints with OpenAPI documentation
- 🎨 **Blazor Web Interface** - Modern responsive UI for image upload and gallery
- ☁️ **S3 Integration** - Secure cloud storage with public read access
- 🏗️ **CloudFormation IaC** - Automated infrastructure provisioning with bucket policies
- 📊 **Aspire Orchestration** - Service discovery, monitoring, and hot reload
- 🔍 **Scalar API Documentation** - Modern API testing interface
- 🖼️ **Image Gallery** - Responsive grid layout with thumbnails and metadata
- 📋 **File Validation** - Size, type, and extension validation
- 🎯 **Interactive Server Components** - Real-time UI updates

### **🛣️ Future Roadmap**

- 📬 **SQS Integration** - Async image processing queues
- 🗄️ **DynamoDB** - Metadata and image catalog storage
- 🔄 **Image Processing** - Thumbnail generation and optimization
- 🔐 **Advanced Security** - IAM roles and fine-grained permissions
- 🗑️ **Image Management** - Delete and list operations

## 🎯 What You'll Learn

- **CloudFormation Templates** - Infrastructure as Code with S3 bucket policies
- **Aspire Service Orchestration** - Microservices coordination and discovery
- **S3 Integration Patterns** - Secure file upload with public read access
- **Blazor File Upload Components** - Modern web UI with InputFile components
- **RESTful API Design** - Image processing endpoints with validation
- **Cloud-Native Architecture** - Scalable distributed application patterns
- **Environment Variable Management** - CloudFormation outputs to service configuration

## 🏗️ Technology Stack

### **Backend & Infrastructure**

- **.NET 9** - Latest .NET framework with C# 13
- **Aspire 9.3.1** - Cloud-native orchestration and service discovery
- **AWS SDK for .NET** - S3 integration and AWS services
- **CloudFormation** - Infrastructure as Code with JSON templates
- **OpenAPI/Swagger** - API documentation and specification
- **Scalar** - Modern API documentation UI

### **Frontend & UI**

- **Blazor Server** - Interactive server-side rendering
- **Bootstrap** - Responsive CSS framework
- **InputFile Components** - HTML5 file upload with validation
- **SignalR** - Real-time UI updates (via Blazor Server)

### **Development & Tooling**

- **Central Package Management** - `Directory.Packages.props` for version control
- **OpenTelemetry** - Distributed tracing and monitoring
- **HTTP Resilience** - Retry policies and circuit breakers
- **Service Discovery** - Aspire-based inter-service communication

## 🏗️ Solution Architecture

```plaintext
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Blazor Web    │───▶│   API Service    │───▶│   AWS S3        │
│   (Upload UI)   │    │  (Image Upload)  │    │ (Public Storage)│
│   - File Select │    │  - Validation    │    │ - Public URLs   │
│   - Gallery     │    │  - S3 Client     │    │ - CORS Enabled  │
│   - Progress    │    │  - Scalar UI     │    │ - Bucket Policy │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌──────────────────┐
                    │  Aspire AppHost  │
                    │   (Orchestrator) │
                    │  - Service Disc. │
                    │  - Hot Reload    │
                    │  - Monitoring    │
                    └──────────────────┘
                                 │
                    ┌──────────────────┐
                    │  CloudFormation  │
                    │  (Infrastructure)│
                    │  - S3 Bucket     │
                    │  - Bucket Policy │
                    │  - CORS Config   │
                    └──────────────────┘
```

## ✅ Working Implementation

This demo is **fully functional** and demonstrates:

### **🎯 Core Functionality**

- **Image Upload**: Select images (JPG, PNG, GIF, WebP, BMP) up to 10MB
- **S3 Storage**: Automatic upload to AWS S3 with organized folder structure (`images/{guid}/{filename}`)
- **Public Access**: Images are immediately accessible via public URLs
- **Gallery View**: Responsive grid layout with thumbnails, metadata, and "View Full Size" links
- **Real-time UI**: Interactive server components with progress indicators
- **API Documentation**: Scalar UI at `/scalar/v1` for API testing

### **🏗️ Infrastructure**

- **Automatic Provisioning**: CloudFormation creates S3 bucket on first run
- **Public Read Access**: Bucket policy allows public access to uploaded images
- **CORS Configuration**: Proper CORS setup for web browser access
- **Environment Variables**: CloudFormation outputs automatically passed to services

### **🔗 Access Points**

| Service              | URL                                | Description                       |
| -------------------- | ---------------------------------- | --------------------------------- |
| **Aspire Dashboard** | `https://localhost:17015`          | Service monitoring and management |
| **Blazor Web App**   | `https://localhost:7XXX`           | Image upload interface            |
| **API Service**      | `https://localhost:7XXX`           | RESTful API endpoints             |
| **Scalar API Docs**  | `https://localhost:7XXX/scalar/v1` | Interactive API documentation     |

### **🌐 Web Application Pages**

| Page             | Route      | Description                                         |
| ---------------- | ---------- | --------------------------------------------------- |
| **Home**         | `/`        | Welcome page with project overview                  |
| **Image Upload** | `/images`  | **Main feature** - Upload images to S3 with gallery |
| **Counter**      | `/counter` | Demo interactive counter page                       |
| **Weather**      | `/weather` | Demo weather forecast page                          |

### **📁 Key Project Structure**

```plaintext
src/
├── AspireAwsStack.AppHost/              # Aspire orchestrator
│   ├── infrastructure/
│   │   └── resources.template           # CloudFormation template (JSON)
│   └── Program.cs                       # Service configuration & deployment
├── AspireAwsStack.ApiService/           # Image upload API
│   ├── Models/ImageModels.cs           # Data models & validation
│   ├── Services/S3ImageService.cs      # S3 operations & upload logic
│   └── Program.cs                      # API endpoints & Scalar UI setup
├── AspireAwsStack.Web/                  # Blazor frontend
│   ├── Components/Pages/ImageUpload.razor  # Main upload interface
│   ├── Models/ImageModels.cs           # UI-specific models
│   ├── Services/ImageUploadService.cs  # HTTP client service
│   └── WeatherApiClient.cs             # Demo weather service
└── AspireAwsStack.ServiceDefaults/      # Shared configuration
    └── Extensions.cs                   # Common service extensions
```

## 🚀 Getting Started

### Prerequisites

- **.NET 9 SDK** - Latest .NET runtime
- **AWS CLI** - Configured with valid credentials
- **Aspire Workload** - `dotnet workload install aspire`
- **AWS Account** - With S3 and CloudFormation permissions

### Quick Start

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/dn9-aspire-cloudformation-s3.git
   cd dn9-aspire-cloudformation-s3
   ```

2. **Configure AWS credentials**

   ```bash
   aws configure
   ```

   > **Note**: AWS credentials will be stored in `C:\Users\<YourUserName>\.aws\`
   >
   > - `credentials` file contains access keys
   > - `config` file contains region and output preferences

3. **Run the application**

   ```bash
   dotnet run --project src/AspireAwsStack.AppHost
   ```

4. **Access the applications**
   - 🎯 **Aspire Dashboard**: `https://localhost:15888`
   - 🌐 **Blazor Web App**: `https://localhost:7001`
   - 🔌 **API Service**: `https://localhost:7002`

## 📁 Project Structure

```plaintext
dn9-aspire-cloudformation-s3/
├── src/
│   ├── AspireAwsStack.AppHost/           # Aspire orchestration
│   │   ├── infrastructure/
│   │   │   └── resources.template        # CloudFormation template (JSON)
│   │   ├── Program.cs                    # AppHost configuration
│   │   └── appsettings.json             # App settings
│   ├── AspireAwsStack.ApiService/        # Image upload API
│   │   ├── Models/
│   │   │   └── ImageModels.cs           # Data models
│   │   ├── Services/
│   │   │   └── S3ImageService.cs        # S3 operations
│   │   ├── Program.cs                   # API endpoints & configuration
│   │   └── appsettings.json            # API settings
│   ├── AspireAwsStack.Web/               # Blazor web interface
│   │   ├── Components/
│   │   │   ├── Layout/                  # Layout components
│   │   │   └── Pages/
│   │   │       ├── ImageUpload.razor    # Image upload page
│   │   │       ├── Home.razor           # Home page
│   │   │       ├── Counter.razor        # Demo counter page
│   │   │       └── Weather.razor        # Demo weather page
│   │   ├── Models/
│   │   │   └── ImageModels.cs          # UI models
│   │   ├── Services/
│   │   │   └── ImageUploadService.cs   # HTTP client service
│   │   ├── WeatherApiClient.cs         # Demo weather client
│   │   └── Program.cs                  # Web app configuration
│   └── AspireAwsStack.ServiceDefaults/   # Shared configurations
│       └── Extensions.cs               # Common service extensions
├── docs/
│   └── images/                         # Documentation assets
├── .github/
│   └── workflows/                      # CI/CD pipelines (empty)
├── Directory.Build.props               # Build configuration
├── Directory.Packages.props            # Centralized package management
├── dn9-aspire-cloudformation-s3.sln   # Solution file
├── .gitignore                         # Git ignore rules
├── LICENSE                            # License file
└── README.md                          # This documentation
```

## 🛠️ Key Components

### **AspireAwsStack.ApiService**

- **Image Upload API**: `POST /api/images/upload` endpoint with file validation
- **S3 Integration**: AWS SDK for S3 with bucket operations and public URL generation
- **Scalar API Documentation**: Modern interactive API documentation at `/scalar/v1`
- **File Validation**: Size limits (10MB), format validation (JPG, PNG, GIF, WebP, BMP)
- **S3ImageService**: Dedicated service class for S3 operations and metadata handling

### **AspireAwsStack.Web (Blazor)**

- **Image Upload Page**: Interactive file upload with drag-and-drop support at `/images`
- **Gallery Display**: Responsive image grid with thumbnails and metadata
- **Progress Tracking**: Real-time upload progress indicators
- **Navigation**: Home, Counter (demo), Weather (demo), and Image Upload pages
- **ImageUploadService**: HTTP client service for API communication
- **Interactive Server Rendering**: Real-time UI updates with `@rendermode InteractiveServer`

### **AspireAwsStack.AppHost**

- **CloudFormation Integration**: Automatic S3 bucket provisioning with `resources.template`
- **Service Discovery**: Aspire service orchestration and communication
- **Environment Variables**: CloudFormation outputs passed to services (S3 bucket name)
- **Infrastructure as Code**: JSON-based CloudFormation template with bucket policies and CORS

### **AspireAwsStack.ServiceDefaults**

- **Common Extensions**: Shared service configuration and resilience patterns
- **OpenTelemetry**: Distributed tracing and monitoring setup
- **Service Discovery**: HTTP client configuration for inter-service communication

## 🌟 Features

- ✅ **Drag & Drop Upload** - Intuitive file upload experience
- ✅ **Image Preview** - Real-time preview before upload
- ✅ **Progress Tracking** - Upload progress indicators
- ✅ **Error Handling** - Comprehensive error management
- ✅ **Security** - IAM-based access control
- ✅ **Monitoring** - Aspire dashboard integration

## � Troubleshooting

### **Common Issues**

#### 1. **CloudFormation "Policy has invalid resource" Error**

If you see an error like `Policy has invalid resource (Service: S3, Status Code: 400)` during CloudFormation stack creation, this indicates an issue with the S3 bucket policy ARN format:

```plaintext
S3BucketPolicy CREATE_FAILED
Resource handler returned message: "Policy has invalid resource (Service: S3, Status Code: 400)"
```

**Solution**: The CloudFormation template has been fixed to use the correct ARN format. If you encounter this error:

1. Delete the failed stack:

   ```bash
   aws cloudformation delete-stack --stack-name AspireAwsStackResources
   ```

2. Wait for deletion and restart the Aspire AppHost:

   ```bash
   aws cloudformation wait stack-delete-complete --stack-name AspireAwsStackResources
   dotnet run --project src/AspireAwsStack.AppHost
   ```

#### 2. **CloudFormation Stack Update Failures**

If you encounter errors when updating the CloudFormation stack (e.g., after manually deleting the S3 bucket), you may need to delete and recreate the stack:

```bash
# Delete the existing CloudFormation stack
aws cloudformation delete-stack --stack-name AspireAwsStackResources

# Wait for deletion to complete (this may take a few minutes)
aws cloudformation wait stack-delete-complete --stack-name AspireAwsStackResources

# Verify the stack is deleted
aws cloudformation describe-stacks --stack-name AspireAwsStackResources
```

After deletion, restart the Aspire AppHost and the stack will be recreated automatically.

#### 3. **AWS Credentials Issues**

- Ensure AWS CLI is configured: `aws configure list`
- Verify credentials have S3 and CloudFormation permissions
- Check region settings match your AWS account setup

#### 3. **S3 Upload Failures**

- Verify the S3 bucket was created by CloudFormation
- Check bucket policy allows public read access
- Ensure CORS configuration is properly set

#### 4. **Aspire Service Discovery Issues**

- Restart the AppHost if services aren't communicating
- Check Aspire Dashboard for service health status
- Verify environment variables are being passed correctly

### **Development Tips**

- Use the Aspire Dashboard (`https://localhost:15888`) to monitor services
- Test API endpoints directly using Scalar UI (`/scalar/v1`)
- Check CloudFormation stack status in AWS Console
- Monitor S3 bucket contents through AWS Console

## �🔮 Upcoming Features

- 🔄 **SQS Processing** - Async image processing workflows
- 🗄️ **DynamoDB Catalog** - Image metadata and search
- 🖼️ **Thumbnail Generation** - Automatic image optimization
- 🔐 **Advanced Security** - Pre-signed URLs and bucket policies
- 🗑️ **Image Management** - Delete and list operations via API

## 🤝 Contributing

Built and maintained by **ShyvnTech** for educational demos and hands-on workshops.

Found an issue or want to contribute? Feel free to open an issue or submit a pull request!

---

⭐ **Star this repo** if it helps you learn .NET Aspire with AWS CloudFormation and S3!
