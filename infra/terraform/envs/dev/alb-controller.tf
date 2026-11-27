module "alb_controller_irsa" {
  #checkov:skip=CKV_TF_1:Registry module pinned by version constraint
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"

  name                                   = "foodhub-dev-alb-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

output "alb_controller_role_arn" {
  value = module.alb_controller_irsa.arn
}
