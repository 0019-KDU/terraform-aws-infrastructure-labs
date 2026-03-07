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
  region = "ap-south-1"
}

# Create an S3 bucket
resource "aws_s3_bucket" "first_bucket" {
  bucket = "chiradev-s3-bucket-0019"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}
