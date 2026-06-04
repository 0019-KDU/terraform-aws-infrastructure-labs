output "bucket_name" {
  description = "Created S3 bucket name"
  value       = aws_s3_bucket.demo.bucket
}

output "bucket_arn" {
  description = "Created S3 bucket ARN"
  value       = aws_s3_bucket.demo.arn
}

output "tags_used" {
  description = "Merged tags applied to the bucket"
  value       = local.merged_tags
}

output "allowed_cidr_blocks" {
  description = "Example list(string) variable output"
  value       = var.allowed_cidr_blocks
}

output "availability_zones" {
  description = "Example set(string) variable output"
  value       = var.availability_zones
}

output "name_parts" {
  description = "Example tuple value"
  value       = var.name_parts
}

output "app_config" {
  description = "Example object value"
  value       = var.app_config
}

output "instance_count_as_string" {
  description = "Example explicit type conversion"
  value       = local.instance_count_as_string
}

output "project_name_type" {
  description = "Terraform detected type of project_name (always string)"
  value       = "string"
}

output "app_config_type" {
  description = "Terraform detected type of app_config (always object)"
  value       = "object"
}