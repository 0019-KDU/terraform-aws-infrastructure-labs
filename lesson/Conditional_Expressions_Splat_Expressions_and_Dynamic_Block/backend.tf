terraform {
  backend "s3" {
    bucket = "chiradev-tf-lab-697502032879-ap-south-1-an"
    key    = "lesson/Expressions/terraform.tfstate"
    region = "ap-south-1"
  }
}
