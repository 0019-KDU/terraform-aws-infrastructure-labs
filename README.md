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
