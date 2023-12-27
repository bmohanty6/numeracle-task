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

