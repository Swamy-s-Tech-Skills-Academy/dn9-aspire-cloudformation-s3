# .NET 9 Aspire CloudFormation S3 - Image Upload Demo

🌩️ A comprehensive .NET 9 Aspire demo showcasing image upload functionality with AWS CloudFormation and Amazon S3 integration. Learn to build scalable cloud-native applications with infrastructure as code.

## 🚀 Overview

This hands-on demo demonstrates how to build a complete image upload solution using .NET 9 Aspire, featuring:

### **Core Features (Phase 1)**

- 📤 **Image Upload API** - RESTful endpoints for image processing
- 🎨 **Blazor Web Interface** - Modern UI for image upload and management
- ☁️ **S3 Integration** - Secure cloud storage with AWS S3
- 🏗️ **CloudFormation IaC** - Automated infrastructure provisioning
- 📊 **Aspire Orchestration** - Service discovery and monitoring

### **Future Roadmap**

- 📬 **SQS Integration** - Async image processing queues
- 🗄️ **DynamoDB** - Metadata and image catalog storage
- 🔄 **Image Processing** - Thumbnail generation and optimization
- 🔐 **Advanced Security** - IAM roles and bucket policies

## 🎯 What You'll Learn

- **CloudFormation Templates** - Infrastructure as Code best practices
- **Aspire Service Orchestration** - Microservices coordination and discovery
- **S3 Integration Patterns** - Secure file upload and storage strategies
- **Blazor File Upload Components** - Modern web UI development
- **RESTful API Design** - Image processing endpoints
- **Cloud-Native Architecture** - Scalable distributed application patterns

## 🏗️ Solution Architecture

```plaintext
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Blazor Web    │───▶│   API Service    │───▶│   AWS S3        │
│   (Upload UI)   │    │  (Image Upload)  │    │   (Storage)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌──────────────────┐
                    │  Aspire AppHost  │
                    │   (Orchestrator) │
                    └──────────────────┘
                                 │
                    ┌──────────────────┐
                    │  CloudFormation  │
                    │  (Infrastructure)│
                    └──────────────────┘
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

## 🔮 Upcoming Features

- 🔄 **SQS Processing** - Async image processing workflows
- 🗄️ **DynamoDB Catalog** - Image metadata and search
- 🖼️ **Thumbnail Generation** - Automatic image optimization
- 🔐 **Advanced Security** - Pre-signed URLs and bucket policies

## 🤝 Contributing

Built and maintained by **ShyvnTech** for educational demos and hands-on workshops.

---

⭐ **Star this repo** if it helps you learn .NET Aspire with AWS!
