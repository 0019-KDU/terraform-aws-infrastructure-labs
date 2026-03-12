terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Input variable 

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "project_name" {
  description = "Project_name"
  type        = string
  default     = "devops-lab"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}


# Local variable

locals {
  instance_name = "${var.project_name}-${var.environment}-server"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


# Resource


resource "aws_instance" "web" {

  ami           = "ami-0f559c3642608c138" # Amazon Linux (example)
  instance_type = var.instance_type

  tags = merge(
    local.common_tags,
    {
      Name = local.instance_name
    }
  )
}


# Outputs


output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "Public IP of the instance"
  value       = aws_instance.web.public_ip
}

output "instance_name" {
  value = local.instance_name
}