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