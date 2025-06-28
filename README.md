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

### **📁 Project Structure**

```
src/
├── AspireAwsStack.AppHost/              # Aspire orchestrator
│   ├── infrastructure/
│   │   └── resources.template           # CloudFormation template
│   └── Program.cs                       # Service configuration
├── AspireAwsStack.ApiService/           # Image upload API
│   ├── Models/ImageModels.cs           # Data models
│   ├── Services/S3ImageService.cs      # S3 operations
│   └── Program.cs                      # API endpoints
├── AspireAwsStack.Web/                  # Blazor frontend
│   ├── Components/Pages/ImageUpload.razor  # Upload interface
│   ├── Models/ImageModels.cs           # UI models
│   └── Services/ImageUploadService.cs  # HTTP client service
└── AspireAwsStack.ServiceDefaults/      # Shared configuration
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
│   ├── AspireAwsStack.ApiService/        # Image upload API
│   ├── AspireAwsStack.Web/               # Blazor web interface
│   └── AspireAwsStack.ServiceDefaults/   # Shared configurations
├── infrastructure/
│   ├── s3-bucket.yaml                    # CloudFormation template
│   └── iam-roles.yaml                    # IAM permissions
├── docs/
│   └── images/                           # Documentation assets
├── .github/
│   └── workflows/                        # CI/CD pipelines
└── README.md
```

## 🛠️ Key Components

### **AspireAwsStack.ApiService**

- Image upload endpoints (`POST /api/images`)
- S3 client integration with AWS SDK
- Image validation and processing
- Metadata extraction and storage

### **AspireAwsStack.Web (Blazor)**

- File upload component with drag-and-drop
- Image preview and progress tracking
- Gallery view of uploaded images
- Responsive modern UI

### **AspireAwsStack.AppHost**

- Service discovery and configuration
- CloudFormation stack management
- Environment variable injection
- Health check orchestration

## 🌟 Features

- ✅ **Drag & Drop Upload** - Intuitive file upload experience
- ✅ **Image Preview** - Real-time preview before upload
- ✅ **Progress Tracking** - Upload progress indicators
- ✅ **Error Handling** - Comprehensive error management
- ✅ **Security** - IAM-based access control
- ✅ **Monitoring** - Aspire dashboard integration

## � Troubleshooting

### **Common Issues**

#### 1. **CloudFormation Stack Update Failures**

If you encounter errors when updating the CloudFormation stack (e.g., after manually deleting the S3 bucket), you may need to delete and recreate the stack:

```bash
# Delete the existing CloudFormation stack
aws cloudformation delete-stack --stack-name AspireAwsStack-resources

# Wait for deletion to complete (this may take a few minutes)
aws cloudformation wait stack-delete-complete --stack-name AspireAwsStack-resources

# Verify the stack is deleted
aws cloudformation describe-stacks --stack-name AspireAwsStack-resources
```

After deletion, restart the Aspire AppHost and the stack will be recreated automatically.

#### 2. **AWS Credentials Issues**

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
