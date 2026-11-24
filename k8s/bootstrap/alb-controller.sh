#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../infra/terraform/envs/dev"
ROLE_ARN=$(terraform output -raw alb_controller_role_arn)
VPC_ID=$(terraform output -raw vpc_id)
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=foodhub-dev \
  --set region=ap-south-1 \
  --set vpcId="$VPC_ID" \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$ROLE_ARN" \
  --set replicaCount=1
