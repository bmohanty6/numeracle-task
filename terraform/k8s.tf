provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}
resource "kubernetes_namespace_v1" "numeracle" {
  metadata {
    annotations = {
      name = "numeracle"
    }
    labels = {
      app = "DemoApp"
    }
    name = "numeracle"
  }
}
resource "kubernetes_deployment_v1" "numeracle-demo-app" {
  metadata {
    name = "demo-app"
    namespace = "numeracle"
    labels = {
      app = "DemoApp"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "DemoApp"
      }
    }
    template {
      metadata {
        labels = {
          app = "DemoApp"
        }
      }
      spec {
        container {
          image = "bmohanty6/numeracle-demo:latest"
          name  = "demo-app"
          ports {
            name = "default"
            containerPort = 8080
            protocol = "http"
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
          liveness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "numeracle-demo-app" {
  metadata {
    name = "demo-app"
    namespace = "numeracle"
    annotations = {
        "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
    }
  }
  spec {
    selector = {
      app = "DemoApp"
    }
    port {
      port        = 8080
      target_port = 8080
      protocol    = "http"
    }
    type = "LoadBalancer"
  }
  wait_for_load_balancer = true
}

# resource "kubernetes_ingress_v1" "numeracle-demo-app" {
#   wait_for_load_balancer = true
#   metadata {
#     name = "demo-app"
#   }
#   spec {
#     ingress_class_name = "numeracle-ingress"
#     rule {
#       http {
#         path {
#           path = "/*"
#           backend {
#             service {
#               name = kubernetes_service_v1.numeracle-demo-app.metadata.0.name
#               port {
#                 number = 8080
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }

# Display load balancer hostname (typically present in AWS)
output "service_all" {
  value = kubernetes_service_v1.numeracle-demo-app
}

# # Display load balancer IP (typically present in GCP, or using Nginx ingress controller)
# output "load_balancer_ip" {
#   value = kubernetes_ingress_v1.numeracle-demo-app.status.0.load_balancer.0.ingress.0.ip
# }