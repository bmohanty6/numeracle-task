terraform {
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = ">=4.57"
      }
    }
}
provider "aws" {
  region = var.aws_region
}
module "terraform_state_backend" {
  source = "cloudposse/tfstate-backend/aws"
  namespace       = "numeracle"
  stage           = "demo"
  s3_bucket_name  = "numeracle-demo-tfstate"

  terraform_backend_config_file_path = "."
  terraform_backend_config_file_name = "backend.tf"
  force_destroy                      = false
}