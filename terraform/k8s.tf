provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
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
    name = var.k8s_app_name
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
            name = "default"
            container_port = 8080
            protocol = "TCP"
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
    name = var.k8s_app_name
    namespace = var.namespace
    annotations = {
        "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
    }
  }
  spec {
    selector = {
      app = var.k8s_app_name
    }
    port {
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }
    type = "LoadBalancer"
  }
  wait_for_load_balancer = true
}

