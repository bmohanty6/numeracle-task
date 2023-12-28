variable "aws_region" {
  type      = string
  default   = "us-east-1"
}
variable "org" {
  default = "numeracle"
}
variable "cluster_name" {
  type = string  
}
variable "eks_version" {
  type = string
  default = "1.28"
}
variable "eks_managed_node_groups" {  
}
variable "namespace" {
  type= string
  default = "numeracle"
}
variable "k8s_app_name" {
  type = string
}
variable "image_name" {
  type = string
  default = "bmohanty6/numeracle-demo:latest"
}