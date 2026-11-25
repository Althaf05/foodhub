#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../infra/terraform/envs/dev"
ROLE_ARN=$(terraform output -raw eso_role_arn)
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
helm upgrade --install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace \
  --set serviceAccount.name=external-secrets \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$ROLE_ARN"
