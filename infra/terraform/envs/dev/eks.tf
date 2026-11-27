module "eks" {
  #checkov:skip=CKV_TF_1:Registry module pinned by version constraint
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "foodhub-dev"
  kubernetes_version = "1.33"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
      configuration_values = jsonencode({
        enableNetworkPolicy = "true"
      })
    }
  }

  eks_managed_node_groups = {
    spot = {
      capacity_type  = "SPOT"
      instance_types = ["m7i-flex.large", "c7i-flex.large"]
      min_size       = 2
      max_size       = 5
      desired_size   = 3
    }
  }
}

output "cluster_name" {
  value = module.eks.cluster_name
}
