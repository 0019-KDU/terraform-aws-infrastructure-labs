# Terraform AWS Infrastructure Labs

This repository contains my hands-on learning journey with Terraform and AWS, covering both theoretical concepts and practical infrastructure provisioning examples.

The goal of this repository is to understand Infrastructure as Code (IaC) and build reproducible cloud infrastructure using Terraform.

## What is Infrastructure as Code (IaC)?

Infrastructure as Code is the practice of managing and provisioning infrastructure through code instead of manual processes.

This allows teams to automate cloud resources such as servers, networks, and storage.

## Why Infrastructure as Code?

- **Consistency** – identical environments across dev, staging, and production
- **Time Efficiency** – automated provisioning saves hours of manual work
- **Cost Management** – easier to track resources and remove unused infrastructure
- **Scalability** – deploy hundreds of resources quickly
- **Version Control** – track infrastructure changes using Git
- **Reduced Human Error** – eliminate manual configuration mistakes
- **Collaboration** – teams can manage infrastructure together

## Benefits of IaC

- Consistent environment deployment
- Write once, deploy many (single codebase)
- Time-saving automation
- Reduced human error
- Cost optimization
- Version control for infrastructure
- Automated cleanup
- Easy troubleshooting using identical environments

## What is Terraform?

Terraform is an Infrastructure as Code tool created by HashiCorp that allows you to define, provision, and manage infrastructure across multiple cloud providers.

Terraform supports:
- AWS
- Azure
- Google Cloud
- Kubernetes
- Many other platforms

## Terraform Workflow

Terraform uses a simple workflow:

1. `terraform init` → Initialize Terraform working directory
2. `terraform validate` → Validate configuration files
3. `terraform plan` → Preview infrastructure changes
4. `terraform apply` → Create or update infrastructure
5. `terraform destroy` → Remove infrastructure

Each lesson contains theory + practical examples.

## Install Terraform

Official installation guide: https://developer.hashicorp.com/terraform/install

### Common Installation Commands

#### macOS

```bash
brew install hashicorp/tap/terraform
```

#### Ubuntu / Debian

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | \
sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update
sudo apt install terraform
```

### Setup Commands

```bash
terraform -install-autocomplete
alias tf=terraform
terraform -version
```

### Common Installation Error (macOS)

If you encounter:

```
Error: No developer tools installed.
```

Run:

```bash
xcode-select --install
```

## AWS CLI Installation

Before creating resources, you need AWS CLI and credentials for Terraform to authenticate with AWS APIs.

### Prerequisites

1. **Create AWS Account**: Sign up for AWS free tier if you don't have an account
2. **Install AWS CLI**: Download and install from AWS official website
3. **Configure Credentials**: Set up your AWS access keys

### Check System Architecture

```bash
# Linux/macOS
uname -m

# Windows PowerShell
$env:PROCESSOR_ARCHITECTURE
```

Official Website: https://aws.amazon.com/cli/

### Windows

```powershell
# Using MSI installer (recommended)
# Download from: https://awscli.amazonaws.com/AWSCLIV2.msi

# Using winget
winget install Amazon.AWSCLI

# Using chocolatey
choco install awscli
```

### macOS

```bash
# Using official installer
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Using Homebrew
brew install awscli
```

### Ubuntu / Debian

```bash
# Update package index
sudo apt update

# Install AWS CLI v2 (choose based on your architecture)
# For x86_64
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# For ARM64
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"

unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
```

## AWS Authentication

### Authentication Methods

| Method | Use Case | Security Level |
|--------|----------|----------------|
| AWS CLI Configuration | Local development | Medium |
| Environment Variables | CI/CD pipelines | Medium |
| IAM Roles | EC2 instances, ECS, Lambda | High |
| AWS Profiles | Multiple accounts | Medium |
| AWS SSO | Enterprise/Production | High |

### Method 1: AWS CLI Configuration (Development)

```bash
aws configure
```

Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., `ap-south-1`)
- Default output format (`json`)

Credentials are stored in `~/.aws/credentials`.

### Method 2: Environment Variables

```bash
# Linux/macOS
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-south-1"

# Windows PowerShell
$env:AWS_ACCESS_KEY_ID="your-access-key"
$env:AWS_SECRET_ACCESS_KEY="your-secret-key"
$env:AWS_DEFAULT_REGION="ap-south-1"
```

### Method 3: AWS Profiles (Multiple Accounts)

```bash
# Configure named profile
aws configure --profile dev
aws configure --profile prod

# Use specific profile
export AWS_PROFILE=dev

# Or in Terraform provider
provider "aws" {
  profile = "dev"
  region  = "ap-south-1"
}
```

### Method 4: IAM Roles (Production - Recommended)

For EC2 instances, ECS tasks, or Lambda functions:

```hcl
provider "aws" {
  region = "ap-south-1"
  # No credentials needed - uses instance role automatically
}
```

### Verify Authentication

```bash
# Check current identity
aws sts get-caller-identity

# List S3 buckets (test permissions)
aws s3 ls
```

## Production Best Practices

### Security

- **Never commit credentials** to Git repositories
- **Use IAM Roles** instead of access keys in production
- **Enable MFA** for all IAM users
- **Use least privilege** - grant minimum required permissions
- **Rotate access keys** regularly (every 90 days)
- **Use AWS Secrets Manager** for sensitive data
- **Enable CloudTrail** for audit logging

### Terraform State Management

```hcl
# Use remote backend for production
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### Environment Separation

```
environments/
├── dev/
│   ├── main.tf
│   └── terraform.tfvars
├── staging/
│   ├── main.tf
│   └── terraform.tfvars
└── prod/
    ├── main.tf
    └── terraform.tfvars
```

### CI/CD Pipeline Best Practices

1. **Use OIDC** for GitHub Actions / GitLab CI authentication
2. **Run `terraform plan`** on pull requests
3. **Require approval** before `terraform apply` in production
4. **Store state remotely** with locking enabled
5. **Use workspaces** or separate state files per environment

### Cost Management

- Use **AWS Cost Explorer** to monitor spending
- Set up **billing alerts** for budget thresholds
- Tag all resources for cost allocation
- Use **spot instances** for non-critical workloads
- Enable **auto-scaling** to match demand
- Regularly review and remove unused resources

## Lessons

| Lesson | Topic | Description |
|--------|-------|-------------|
| [Provider](lesson/provider/) | Terraform Providers | Understanding providers and version management |
| [S3](lesson/s3/) | S3 Bucket | Creating and managing S3 buckets |
