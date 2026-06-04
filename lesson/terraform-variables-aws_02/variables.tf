variable "aws_region" {
  description = "AWS region where resources will be created"
  type = string
  default = "ap-south-1"
}

variable "project_name" {
  description = "Project name used in resources naming"
  type = string

  validation {
    condition     = length(var.project_name) >= 3 && length(var.project_name) <= 20
    error_message = "project_name must be between 3 and 20 characters."
  }
}

variable "environment" {
  description = "Environment name"
  type = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, prod."
  }
}

variable "bucket_versioning_enabled" {
  description = "Enabled s3 bucket versioing"
  type = bool
  default = true
}

variable "lifecycle_expiration_days" {
  description = "Delete objects after this many days"
  type        = number
  default     = 30

  validation {
    condition     = var.lifecycle_expiration_days >= 1 && var.lifecycle_expiration_days <= 365
    error_message = "lifecycle_expiration_days must be between 1 and 365."
  }
}

variable "common_tags" {
  description = "Common tags applied to resources"
  type = map(string)

  default = {
    "owner" = "chira"
  }
}

variable "allowed_cidr_blocks" {
  description = "Example listy value for learning purpose"
  type = list(string)

  default = [
  "172.31.0.0/20",
  "172.31.16.0/20"
]

validation {
  condition = length(var.alllowed_cidr_blocks)>0
  error_message = "allowed_cidr_blocks must contain at least one CIDR block"
}
}


variable "availability_zones" {
  description = "Example set value for learning: duplicates are remove"
  type = set(string)

  default = [
    "ap-south-1a",
    "ap-south-1b",
    "ap-south-1a"
  ]
}

variable "name_parts" {
  description = "Example tuple with fixed positions and types: [project, env, instance_count]"
  type        = tuple([string, string, number])
  default     = ["demo", "dev", 1]
}

variable "app_config" {
    description = "Application configuration using object type"
    type = object({
      app_name = string
      team_name = string
      enable_logging = bool
      instance_count = number
    })
    default = {
    app_name       = "inventory"
    team_name      = "platform"
    enable_logging = true
    instance_count = 1
  }
}


variable "bucket_settings" {
  description = "S3 bucket settings using object type"
  type = object({
    encryption_enabled       = bool
    block_public_access      = bool
    force_destroy            = bool
    additional_bucket_suffix = string
  })

  default = {
    encryption_enabled       = true
    block_public_access      = true
    force_destroy            = false
    additional_bucket_suffix = "files"
  }
}