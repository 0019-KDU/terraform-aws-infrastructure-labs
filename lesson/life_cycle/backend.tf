terraform {
  backend "s3" {
    bucket = "chiradev-tf-backend-697502032879-ap-south-1-an"
    key    = "lesson/life_cycle/terraform.tfstate"
    region = "ap-south-1"
  }
}
