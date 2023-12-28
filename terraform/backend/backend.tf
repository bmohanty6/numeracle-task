terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    region   = "us-east-1"
    bucket   = "numeracle-demo-tfstate"
    key      = "terraform.tfstate"
    profile  = ""
    encrypt  = "true"

    dynamodb_table = "numeracle-demo-lock"
  }
}
