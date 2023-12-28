## The hostname of the loadbalancer
output "load_balancer" {
  value = kubernetes_service_v1.numeracle-demo-app.status.0.load_balancer.0.ingress.0.hostname
}