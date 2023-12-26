cluster_name = "numeracle-demo"
vpc_id       = "vpc-07e1cbd5b861e3cd1"
subnet_ids   = [ "subnet-0af2d3437b629ee9c","subnet-063557c0b1045f64f",
                 "subnet-092ab45006e5ae242","subnet-0de32a11713d0301d" ]
eks_managed_node_groups = {
    eks_ng_1 = {
        min_size     = 1
        max_size     = 2
        desired_size = 1
        key_name     = "eks_node_key_default"
    }
}