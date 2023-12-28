cluster_name = "numeracle-demo"
eks_managed_node_groups = {
    eks_ng_1 = {
        min_size     = 1
        max_size     = 2
        desired_size = 1
        key_name     = "eks_node_key_default"
    }
}
k8s_app_name = "demo-app"