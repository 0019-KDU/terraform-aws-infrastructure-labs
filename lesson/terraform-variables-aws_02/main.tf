locals {
  bucket_name = lower(
    "${var.project_name}-${var.environment}-${var.bucket_settings.additional_bucket_suffix}"
  )

  merged_tags = merge(
    var.common_tags,
    {
      project     = var.project_name
      environment = var.environment
      app         = var.app_config.app_name
      team        = var.app_config.team_name
    }
  )

  # example of light type normalization
  instance_count_as_string = tostring(var.app_config.instance_count)
}

resource "aws_s3_bucket" "demo" {
  bucket        = local.bucket_name
  force_destroy = var.bucket_settings.force_destroy

  tags = local.merged_tags
}

resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id

  versioning_configuration {
    status = var.bucket_versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
  count  = var.bucket_settings.encryption_enabled ? 1 : 0
  bucket = aws_s3_bucket.demo.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "demo" {
  count  = var.bucket_settings.block_public_access ? 1 : 0
  bucket = aws_s3_bucket.demo.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "demo" {
  bucket = aws_s3_bucket.demo.id

  rule {
    id     = "expire-old-objects"
    status = "Enabled"

    expiration {
      days = var.lifecycle_expiration_days
    }
  }
}