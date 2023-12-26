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
variable "vpc_id" {
  type = string
}
variable "subnet_ids" {
  type = list(string)
}
variable "eks_managed_node_groups" {
  
}