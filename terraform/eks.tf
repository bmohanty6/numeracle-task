

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

locals {
  vpc_cidr = "172.31.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    cluster    = var.cluster_name
    org        = var.org
  }
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
  vpc_id                            = var.vpc_id
  subnet_ids                        = var.subnet_ids
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
    # remote_access  = {
    #     ec2_ssh_key               = "eks_node_key_default"
    #     source_security_group_ids = [aws_security_group.remote_access.id]
    # }
  }
  eks_managed_node_groups = var.eks_managed_node_groups
  tags = local.tags
}

################################################################################
# Supporting Resources
################################################################################

resource "aws_key_pair" "eks_node_key_default" {
  key_name   = "eks_node_key_default"
  public_key = file("./eks_node_key_default.pub")
}

resource "aws_security_group" "remote_access" {
  name_prefix = "${var.cluster_name}-remote-access"
  description = "Allow remote SSH access"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.tags, { Name = "${var.cluster_name}-remote" })
}

resource "aws_iam_policy" "node_additional" {
  name        = "${var.cluster_name}-additional"
  description = "Example usage of node additional policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = local.tags
}

