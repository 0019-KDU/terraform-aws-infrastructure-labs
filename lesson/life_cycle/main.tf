resource "aws_instance" "demo" {
  ami           = "ami-0912f71e06545ad88"
  instance_type = var.allowed_vm_types[1]

  tags = var.resource_tags

  lifecycle {
    create_before_destroy = true
  }
}


# ==============================
# Example 2: prevent_destroy
# Use Case: Critical S3 bucket that should never be accidentally deleted
# ==============================
resource "aws_s3_bucket" "critical_data"{

  bucket = "my"
}