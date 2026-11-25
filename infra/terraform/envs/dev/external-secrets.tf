data "aws_iam_policy_document" "eso_read_jwt" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [
      "arn:aws:secretsmanager:ap-south-1:${data.aws_caller_identity.current.account_id}:secret:foodhub/jwt-*",
      "arn:aws:secretsmanager:ap-south-1:${data.aws_caller_identity.current.account_id}:secret:foodhub/slack-webhook-*",
    ]
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "eso_read_jwt" {
  name   = "foodhub-dev-eso-read-jwt"
  policy = data.aws_iam_policy_document.eso_read_jwt.json
}

module "eso_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"

  name = "foodhub-dev-external-secrets"

  policies = {
    read_jwt = aws_iam_policy.eso_read_jwt.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets"]
    }
  }
}

output "eso_role_arn" {
  value = module.eso_irsa.arn
}
