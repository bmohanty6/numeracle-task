provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

resource "aws_iam_policy" "alb_lb_controller_irsa_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "AWS LB ingress controller IAM policy"
  policy      = file("./files/abs_lb_controller_access_policy.json")
}

resource "aws_iam_role" "iam_service_account_role" {
  name               = "AWSLoadBalancerControllerIAMRole"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Federated": "${module.eks.oidc_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${module.eks.oidc_provider}:sub": "system:serviceaccount:kube-system:alb-ingress-controller",
          "${module.eks.oidc_provider}:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
POLICY

  depends_on = [module.eks]

  tags = {
    "ServiceAccountName"      = "alb-ingress-controller"
    "ServiceAccountNameSpace" = "kube-system"
  }
}
resource "aws_iam_role_policy_attachment" "iam_service_account_role_policy_attachment" {
  policy_arn = aws_iam_policy.alb_lb_controller_irsa_policy.arn
  role       = aws_iam_role.iam_service_account_role.name
}

resource "kubernetes_service_account_v1" "iam_service_account" {
  metadata {
    name      = "alb-ingress-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.iam_service_account_role.arn
    }
  }
}
resource "kubernetes_namespace_v1" "numeracle" {
  metadata {
    name = "kube-system"
  }
}
resource "helm_release" "aws_alb_ingress" {
  name       = "alb-ingress-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }
  set {
    name  = "serviceAccount.create"
    value = false
  }
  set {
    name  = "serviceAccount.name"
    value = "alb-ingress-controller"
  }
}

resource "kubernetes_namespace_v1" "numeracle" {
  metadata {
    annotations = {
      name = var.namespace
    }
    labels = {
      app = var.k8s_app_name
    }
    name = var.namespace
  }
}
resource "kubernetes_deployment_v1" "numeracle-demo-app" {
  metadata {
    name      = var.k8s_app_name
    namespace = var.namespace
    labels = {
      app = var.k8s_app_name
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = var.k8s_app_name
      }
    }
    template {
      metadata {
        labels = {
          app = var.k8s_app_name
        }
      }
      spec {
        container {
          image = var.image_name
          name  = var.k8s_app_name
          port {
            name           = "http-default"
            container_port = 8080
            protocol       = "TCP"
          }
          resources {
            limits = {
              cpu    = "0.5"
              memory = "1024Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "numeracle-demo-app" {
  metadata {
    name      = var.k8s_app_name
    namespace = var.namespace
  }
  spec {
    selector = {
      app = var.k8s_app_name
    }
    port {
      port        = 8080
      target_port = "http-default"
      protocol    = "TCP"
    }
    type = "clusterIP"
  }
}

resource "kubernetes_ingress_v1" "numeracle-demo-app" {
  metadata {
    name      = var.k8s_app_name
    namespace = var.namespace
    annotations = {
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
      "alb.ingress.kubernetes.io/subnets"     = join(",", module.vpc.private_subnets)
    }
  }
  wait_for_load_balancer = true
  spec {
    ingressClassName = "alb"
    rule {
      http {
        path {
          path = "/"
          backend {
            service {
              name = kubernetes_service_v1.numeracle-demo-app.metadata.0.name
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}
