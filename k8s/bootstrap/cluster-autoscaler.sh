#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../infra/terraform/envs/dev"
ROLE_ARN=$(terraform output -raw cluster_autoscaler_role_arn)
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update
helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler -n kube-system \
  --set autoDiscovery.clusterName=foodhub-dev \
  --set awsRegion=ap-south-1 \
  --set rbac.serviceAccount.name=cluster-autoscaler \
  --set rbac.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$ROLE_ARN" \
  --set resources.requests.cpu=50m --set resources.requests.memory=100Mi
