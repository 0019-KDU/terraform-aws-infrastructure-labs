# String type
variable "environment" {
  type        = string
  description = "The environment type"
  default     = "staging"
}

variable "aws_region" {
  type        = string
  description = "AWS region for resources"
  default     = "ap-south-1"
}

variable "resource_tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default = {
    "environment" = "staging"
    "managed_by"  = "terraform"
    "department"  = "devops"
  }
}

variable "bucket_name" {
  type        = list(string)
  description = "Name of the S3 bucket"
  default     = ["chiradev-s3-bucket-0019", "chiradev-s3-bucket-0020"]
}

variable "bucket_name_set" {
  type        = set(string)
  description = "Name of the S3 bucket"
  default     = ["chiradev-s3-bucket-001910", "chiradev-s3-bucket-002010"]
}

variable "allowed_vm_types"{
    description = "Allowed VM types for EC2 instances"
    type=list(string)
    default=["t2.micro","t3.micro","t2.small","t3.small"]
}

variable "allowed_regions"{
  description = "Allowed AWS regions for resource deployment"
  type=set(string)
  default=["ap-south-1","us-east-1","us-west-2","eu-west-1"]
}


variable "associate_public_ip"{
  description = "Whether to associate a public IP address with the EC2 instance"
  type=bool
  default=true
}

variable "cidr_block"{
  description = "CIDR block for the VPC"
  type=list(string)
  default=["10.0.0.0/8","172.16.0.0/12","192.168.0.0/16"]
}