module "cluster_autoscaler_irsa" {
  #checkov:skip=CKV_TF_1:Registry module pinned by version constraint
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"

  name                             = "foodhub-dev-cluster-autoscaler"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
}

output "cluster_autoscaler_role_arn" {
  value = module.cluster_autoscaler_irsa.arn
}
