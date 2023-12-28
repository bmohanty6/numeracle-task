terraform {
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = ">=4.57"
      }
    }
    backend "s3" {
    region   = "us-east-1"
    bucket   = "numeracle-demo-tfstate"
    key      = "main-terraform.tfstate"
    profile  = ""
    encrypt  = "true"

    dynamodb_table = "numeracle-demo-lock"
  }
}
provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

locals {
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  tags = {
    cluster    = var.cluster_name
    org        = var.org
  }
}
####################
## VPC
####################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  name = var.org
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway     = true
  single_nat_gateway     = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name                      = var.cluster_name
  cluster_version                   = var.eks_version
  cluster_endpoint_public_access    = true
  cluster_endpoint_private_access   = true
  cluster_ip_family                 = "ipv4"
  vpc_id                            = module.vpc.vpc_id
  subnet_ids                        = concat(module.vpc.private_subnets, module.vpc.public_subnets)
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
  manage_aws_auth_configmap = true  

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t3a.medium"]
    disk_size      = 20
    subnet_ids     = module.vpc.private_subnets
  }
  eks_managed_node_groups = var.eks_managed_node_groups
  tags = local.tags
}

resource "aws_key_pair" "eks_node_key_default" {
  key_name   = "eks_node_key_default"
  public_key = file("./files/eks_node_key_default.pub")
}


