# Terraform Remote Backend

## 1. How Terraform Updates Infrastructure

| Concept | Description |
|---------|-------------|
| **Goal** | Keep actual state same as desired state |
| **State File** | Actual state resides in `terraform.tfstate` file |
| **Process** | Terraform compares current state with desired configuration |
| **Updates** | Only changes the resources that need modification |

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  Configuration   │     │   State File     │     │  Real Resources  │
│   (main.tf)      │ ──► │ (terraform.      │ ──► │    (AWS)         │
│                  │     │   tfstate)       │     │                  │
│  Desired State   │     │  Current State   │     │  Actual State    │
└──────────────────┘     └──────────────────┘     └──────────────────┘
```

## 2. Terraform State File

The state file is a JSON file that contains:

- Resource metadata and current configuration
- Resource dependencies
- Provider information
- Resource attribute values

### State File Best Practices

- Never edit state file manually
- Store state file remotely (not in local file system)
- Enable state locking to prevent concurrent modifications
- Backup state files regularly
- Use separate state files for different environments
- Restrict access to state files (contains sensitive data)
- Encrypt state files at rest and in transit

## 3. Why Remote Backend?

**Problems with Local State:**

| Problem | Impact |
|---------|--------|
| No collaboration | Team members can't share state |
| Risk of data loss | State file on local machine |
| No locking | Concurrent changes can corrupt state |
| Security risk | Sensitive data stored locally |

**Remote Backend Benefits:**

- **Collaboration:** Team members can share state
- **Locking:** Prevents concurrent state modifications
- **Security:** Encrypted storage and access control
- **Backup:** Automatic versioning and backup
- **Durability:** Highly available storage

## 4. AWS Remote Backend Components

| Component | Purpose |
|-----------|---------|
| S3 Bucket | Stores the state file |
| S3 Native State Locking | Uses S3 conditional writes for locking (Terraform 1.10+) |
| IAM Policies | Control access to backend resources |

## 5. S3 Native State Locking (NEW)

### What is S3 Native State Locking?

Starting with **Terraform 1.10** (released in 2024), you no longer need DynamoDB for state locking. Terraform now supports S3 native state locking using Amazon S3's **Conditional Writes** feature.

### How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                    S3 Native Locking Process                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Terraform needs lock → Attempts to create .tflock file     │
│                                    ↓                            │
│  2. S3 checks → Does .tflock already exist?                    │
│                     ↓                    ↓                      │
│                   YES                   NO                      │
│                    ↓                     ↓                      │
│            Write FAILS            Write SUCCEEDS                │
│         (lock not acquired)      (lock acquired)                │
│                                        ↓                        │
│  3. Terraform completes operation                               │
│                                        ↓                        │
│  4. Lock file deleted (appears as delete marker)                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Old Method vs New Method

| Feature | Old (DynamoDB) | New (S3 Native) |
|---------|----------------|-----------------|
| Additional Service | Required DynamoDB table | No extra service |
| Cost | DynamoDB read/write charges | Included in S3 |
| Complexity | More IAM permissions | Simpler setup |
| Maintenance | Monitor DynamoDB | Only S3 |
| Status | **Discouraged** | **Recommended** |

**Important:** DynamoDB state locking is now discouraged and may be deprecated in future Terraform versions.

## 6. Configuration Example

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Remote Backend Configuration
  backend "s3" {
    bucket       = "your-terraform-state-bucket"
    key          = "dev/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true    # Enable S3 native state locking
    encrypt      = true    # Enable server-side encryption
  }
}

provider "aws" {
  region = "ap-south-1"
}
```

### Key Parameters

| Parameter | Description |
|-----------|-------------|
| `bucket` | S3 bucket name for state storage |
| `key` | Path within the bucket where state file will be stored |
| `region` | AWS region for the S3 bucket |
| `use_lockfile` | Enable S3 native state locking (set to `true`) |
| `encrypt` | Enable server-side encryption for the state file |

**Important:** S3 versioning **MUST** be enabled for S3 native state locking to work properly.

## 7. Setup Remote Backend

### Step 1: Create S3 Bucket (Before terraform init)

```bash
# Create S3 bucket
aws s3api create-bucket \
  --bucket chiradev-tf-state-backend-2024 \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

# Enable versioning (REQUIRED for state locking)
aws s3api put-bucket-versioning \
  --bucket chiradev-tf-state-backend-2024 \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket chiradev-tf-state-backend-2024 \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket chiradev-tf-state-backend-2024 \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'
```

### Step 2: Initialize Terraform

```bash
terraform init
```

### Step 3: Apply Configuration

```bash
terraform apply
```

## 8. How to Test State Locking

To verify that S3 native state locking is working:

### Test Steps

```bash
# Terminal 1: Start a long-running apply
terraform apply

# Terminal 2: While first is running, try another command
terraform plan
```

### Expected Result

The second command should fail with an error like:

```
Error: Error acquiring the state lock

Error message: operation error S3: PutObject, https response error StatusCode: 412

Lock Info:
  ID:        <lock-id>
  Path:      <bucket>/<key>
  Operation: OperationTypeApply
  Who:       <user>@<hostname>
```

### What Happens in S3

| During Operation | After Completion |
|------------------|------------------|
| `.tflock` file appears in bucket | Lock file deleted |
| Other terraform commands blocked | Bucket ready for next operation |

## 9. Backend Migration

If you have existing local state:

```bash
# Initialize with new backend configuration
terraform init

# Terraform will prompt to migrate existing state
# Answer 'yes' to copy existing state to new backend

# Verify state is now remote
terraform state list
```

## 10. State Commands

```bash
# List resources in state
terraform state list

# Show detailed state information
terraform state show <resource_name>

# Remove resource from state (without destroying)
terraform state rm <resource_name>

# Move resource to different state address
terraform state mv <source> <destination>

# Pull current state and display
terraform state pull

# Force unlock (if lock is stuck)
terraform force-unlock <lock-id>
```

## 11. Multi-Environment Setup

Organize state files by environment:

```
┌─────────────────────────────────────────────┐
│           S3 Bucket Structure               │
├─────────────────────────────────────────────┤
│  chiradev-tf-state-backend-2024/            │
│  ├── dev/                                   │
│  │   ├── vpc/terraform.tfstate              │
│  │   ├── eks/terraform.tfstate              │
│  │   └── rds/terraform.tfstate              │
│  ├── staging/                               │
│  │   ├── vpc/terraform.tfstate              │
│  │   └── eks/terraform.tfstate              │
│  └── prod/                                  │
│      ├── vpc/terraform.tfstate              │
│      ├── eks/terraform.tfstate              │
│      └── rds/terraform.tfstate              │
└─────────────────────────────────────────────┘
```

**Key path format:** `{environment}/{component}/terraform.tfstate`

## 12. Security Considerations

| Area | Recommendation |
|------|----------------|
| S3 Bucket Policy | Restrict access to authorized users only |
| S3 Versioning | Required for state locking; provides rollback capability |
| Encryption | Enable server-side encryption (AES-256 or KMS) |
| Access Logging | Enable CloudTrail for audit logging |
| IAM Permissions | Grant minimal required S3 permissions |
| Public Access | Block all public access to bucket |

### Minimal IAM Policy for S3 Backend

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketVersioning"
      ],
      "Resource": [
        "arn:aws:s3:::your-terraform-state-bucket",
        "arn:aws:s3:::your-terraform-state-bucket/*"
      ]
    }
  ]
}
```

## 13. Common Issues

### State Lock Error

```
Error: Error acquiring the state lock
```

**Cause:** Previous terraform process crashed or lock file remains.

**Solution:**
```bash
# Find lock ID from error message, then:
terraform force-unlock <lock-id>

# Or manually delete .tflock file from S3
aws s3 rm s3://your-bucket/path/.tflock
```

### Permission Errors

```
Error: AccessDenied: Access Denied
```

**Solution:** Ensure proper IAM permissions for S3 operations.

### Versioning Not Enabled

```
Error: S3 bucket versioning is not enabled
```

**Solution:** S3 versioning **MUST** be enabled for native state locking.
```bash
aws s3api put-bucket-versioning \
  --bucket your-bucket \
  --versioning-configuration Status=Enabled
```

### Region Mismatch

**Solution:** Backend region should match your provider region.

### Terraform Version

**Requirement:**
- Terraform 1.10+ for S3 native locking
- Terraform 1.11+ recommended for stable GA release

## 14. Files Overview

```
lesson/remote_backend/
├── main.tf                  # Main configuration with backend
├── terraform.tfvars.example # Example variables file
└── README.md                # This documentation
```

## 15. Cost Estimation

| Resource | Cost |
|----------|------|
| S3 Storage | ~$0.023/GB/month (Standard) |
| S3 Requests | ~$0.005 per 1000 PUT/GET |
| No DynamoDB | $0 (not needed anymore!) |

**Typical monthly cost:** $1-2 for small to medium projects

## 16. Best Practices Summary

- Create S3 bucket **before** configuring backend
- Enable versioning on S3 bucket (required)
- Enable encryption for security
- Block all public access
- Use `use_lockfile = true` for S3 native locking
- Use meaningful key paths for organization
- Restrict IAM access to state bucket
- Use Terraform 1.10+ (1.11+ recommended)
- Test state locking before production use
- Enable CloudTrail for audit logging

## 17. Cleanup

**Warning:** Only destroy test resources, not the backend bucket.

```bash
# Destroy test resources created by Terraform
terraform destroy

# The backend S3 bucket should remain for other projects
# Only delete manually when no longer needed
```
