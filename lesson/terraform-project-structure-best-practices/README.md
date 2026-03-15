# Terraform Project Structure Best Practices

A hands-on lesson demonstrating how to organize Terraform configurations using separation of concerns, logical file grouping, and AWS best practices.

---

## What This Lesson Covers

- How Terraform loads and merges `.tf` files
- Recommended file structure for real-world projects
- File organization principles (separation of concerns, logical grouping)
- Variable validation and local values
- Remote S3 backend with state locking
- S3 bucket with encryption, versioning, and public access block
- VPC with public subnets, Internet Gateway, and route tables

---

## Project File Structure

```
terraform-project-structure-best-practices/
├── backend.tf        # Terraform version, provider requirements, S3 remote backend
├── provider.tf       # AWS provider with default tags
├── variables.tf      # All input variable definitions with validation
├── locals.tf         # Computed local values and naming convention
├── vpc.tf            # VPC, Internet Gateway, public subnets, route tables
├── storage.tf        # S3 bucket with versioning, encryption, access block
├── outputs.tf        # All output values (VPC, subnets, S3, environment)
└── README.md         # This file
```

> **Key insight:** Terraform loads all `.tf` files in the current directory and merges them into a single configuration. File names do not affect functionality — only organization.

---

## Resources Created

### Networking (`vpc.tf`)
| Resource | Description |
|---|---|
| `aws_vpc.main` | VPC with DNS hostnames and support enabled |
| `aws_internet_gateway.main` | Internet Gateway attached to the VPC |
| `aws_subnet.public` | Public subnets (one per availability zone) |
| `aws_route_table.public` | Route table with default route to IGW |
| `aws_route_table_association.public` | Associates route table with each public subnet |

### Storage (`storage.tf`)
| Resource | Description |
|---|---|
| `aws_s3_bucket.main` | S3 bucket with a random unique suffix |
| `aws_s3_bucket_versioning.main` | Versioning enabled |
| `aws_s3_bucket_server_side_encryption_configuration.main` | AES-256 server-side encryption |
| `aws_s3_bucket_public_access_block.main` | All public access blocked |

---

## Input Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `project_name` | `string` | `"chiradev-lab"` | Name of the project |
| `environment` | `string` | `"staging"` | Environment: `dev`, `staging`, or `production` |
| `region` | `string` | `"us-east-1"` | AWS region for resources |
| `vpc_cidr` | `string` | `"10.0.0.0/16"` | CIDR block for the VPC |
| `availability_zones` | `list(string)` | `["us-east-1a", "us-east-1b"]` | List of AZs for public subnets |
| `tags` | `map(string)` | `{}` | Additional tags to apply to all resources |

> **Validation rules:**
> - `environment` must be one of `dev`, `staging`, `production`
> - `vpc_cidr` must be a valid IPv4 CIDR block

---

## Outputs

| Output | Description |
|---|---|
| `vpc_id` | ID of the created VPC |
| `vpc_cidr_block` | CIDR block of the VPC |
| `vpc_arn` | ARN of the VPC |
| `public_subnet_ids` | List of public subnet IDs |
| `public_subnet_cidrs` | List of public subnet CIDR blocks |
| `s3_bucket_name` | Name of the S3 bucket |
| `s3_bucket_arn` | ARN of the S3 bucket |
| `s3_bucket_domain_name` | Domain name of the S3 bucket |
| `environment` | Deployed environment name |
| `region` | Deployed AWS region |
| `common_tags` | Map of common tags applied to all resources |

---

## Remote Backend

State is stored remotely in S3 with file-based locking (`use_lockfile = true`):

```hcl
backend "s3" {
  bucket       = "chiradev-tf-state-backend-2024"
  key          = "dev/terraform.tfstate"
  region       = "ap-south-1"
  use_lockfile = true
  encrypt      = true
}
```

> **Note:** The backend region (`ap-south-1`) is independent of the deployment region. The backend bucket must exist before running `terraform init`.

---

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- S3 backend bucket already created (`chiradev-tf-state-backend-2024`)

---

## Usage

### 1. Initialize

```bash
terraform init
```

### 2. Customize variables (optional)

Create a `terraform.tfvars` file:

```hcl
project_name       = "aws-terraform-course"
environment        = "dev"
region             = "us-east-1"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

tags = {
  Owner      = "DevOps-Team"
  Department = "Engineering"
  CostCenter = "Engineering-001"
}
```

> **Important:** If deploying to a different region (e.g. `ap-south-1`), update `availability_zones` to match:
> ```hcl
> region             = "ap-south-1"
> availability_zones = ["ap-south-1a", "ap-south-1b"]
> ```

### 3. Validate and format

```bash
terraform validate
terraform fmt -recursive
```

### 4. Plan and apply

```bash
terraform plan
terraform apply
```

### 5. Destroy when done

```bash
terraform destroy
```

---

## Naming Convention

All resources follow this pattern, defined in `locals.tf`:

```
{project_name}-{environment}-{resource-type}
```

Examples:
- VPC: `chiradev-lab-staging-vpc`
- IGW: `chiradev-lab-staging-igw`
- Public subnet 1: `chiradev-lab-staging-public-subnet-1`
- Route table: `chiradev-lab-staging-public-rt`

---

## Common Tags

All resources inherit these tags automatically via `default_tags` in the provider and `merge(local.common_tags, {...})` on each resource:

| Tag | Value |
|---|---|
| `Environment` | Value of `var.environment` |
| `Project` | Value of `var.project_name` |
| `ManagedBy` | `Terraform` |
| `CreatedDate` | Date of apply (YYYY-MM-DD) |

---

## Key Learning Points

### How Terraform File Loading Works
- Terraform loads **all `.tf` files** in the current directory
- Files are merged into a **single configuration** in memory
- Load order is lexicographical (alphabetical) — but order rarely matters
- File names are for humans, not Terraform

### File Organization Principles

| Principle | How Applied Here |
|---|---|
| **Separation of Concerns** | Network in `vpc.tf`, storage in `storage.tf` |
| **Logical Grouping** | Resources grouped by AWS service |
| **Consistent Naming** | All files use lowercase with `.tf` extension |
| **Single Responsibility** | Each file focuses on one area |
| **Documentation** | Variables and outputs all have `description` |

### Common Mistakes to Avoid
- Putting everything in `main.tf` — hard to navigate at scale
- Inconsistent file naming — confuses team members
- Hard-coding values — use `variables.tf` instead
- Storing state in Git — always use a remote backend
- Missing variable validation — leads to silent misconfigurations

---

## Advanced Structure Patterns

For larger projects, consider these patterns:

### Environment-Based Structure
```
terraform-repo/
├── environments/
│   ├── dev/
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── prod/
└── modules/
    ├── vpc/
    └── ec2/
```

### Service-Based Structure
```
infrastructure/
├── networking/   # vpc.tf, subnets.tf, routing.tf
├── security/     # security-groups.tf, iam.tf
├── compute/      # ec2.tf, autoscaling.tf
└── storage/      # s3.tf, ebs.tf
```

### Module Structure (Reusable Components)
```
modules/
└── vpc/
    ├── main.tf       # Resources
    ├── variables.tf  # Inputs
    ├── outputs.tf    # Outputs
    └── README.md     # Documentation
```

---

## Provider Requirements

| Provider | Version |
|---|---|
| `hashicorp/aws` | `~> 6.0` |
| `hashicorp/random` | `~> 3.1` |
