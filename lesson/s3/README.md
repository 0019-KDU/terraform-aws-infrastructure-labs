# Terraform S3 Bucket

## 1. What is Amazon S3?

Amazon Simple Storage Service (S3) is an object storage service that offers:
- Scalability
- Data availability
- Security
- Performance

**Common use cases:**
- Static website hosting
- Backup and restore
- Data archiving
- Application data storage
- Log storage

## 2. S3 Key Concepts

| Term | Description |
|------|-------------|
| Bucket | Container for storing objects |
| Object | File stored in a bucket (data + metadata) |
| Key | Unique identifier for an object within a bucket |
| Region | Geographic location where bucket is stored |

## 3. Terraform Resource: aws_s3_bucket

The `aws_s3_bucket` resource creates an S3 bucket in AWS.

### Basic Syntax

```hcl
resource "aws_s3_bucket" "example" {
  bucket = "my-unique-bucket-name"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `bucket` | Optional | Bucket name (must be globally unique) |
| `tags` | Optional | Key-value pairs for resource tagging |

**Note:** Bucket names must be:
- Globally unique across all AWS accounts
- 3-63 characters long
- Lowercase letters, numbers, and hyphens only
- Start with a letter or number

## 4. Code Explanation

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

Configures Terraform to use AWS provider version 6.x.

```hcl
provider "aws" {
  region = "ap-south-1"
}
```

Sets AWS region to Mumbai (ap-south-1).

```hcl
resource "aws_s3_bucket" "first_bucket" {
  bucket = "chiradev-s3-bucket-0019"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}
```

Creates an S3 bucket with:
- Custom bucket name
- Tags for identification

## 5. Terraform Commands

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Create the bucket
terraform apply

# Destroy the bucket
terraform destroy
```

## 6. Verify in AWS Console

After `terraform apply`:
1. Go to AWS Console
2. Navigate to S3
3. Find your bucket by name

## 7. Common S3 Bucket Configurations

### Enable Versioning

```hcl
resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.first_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

### Block Public Access (Recommended)

```hcl
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.first_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### Enable Server-Side Encryption

```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.first_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

## 8. Best Practices

- Use unique, descriptive bucket names
- Enable versioning for important data
- Block public access by default
- Enable server-side encryption
- Use tags for cost tracking and organization
- Enable access logging for auditing

## 9. Common Errors

### Bucket Already Exists

```
Error: creating S3 Bucket: BucketAlreadyExists
```

**Solution:** Choose a different, globally unique bucket name.

### Invalid Bucket Name

```
Error: creating S3 Bucket: InvalidBucketName
```

**Solution:** Follow bucket naming rules (lowercase, no underscores, 3-63 chars).

## 10. Output Values (Optional)

Add outputs to get bucket information:

```hcl
output "bucket_name" {
  value = aws_s3_bucket.first_bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.first_bucket.arn
}

output "bucket_region" {
  value = aws_s3_bucket.first_bucket.region
}
```
