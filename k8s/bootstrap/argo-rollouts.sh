#!/usr/bin/env bash
set -euo pipefail
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argo-rollouts argo/argo-rollouts -n argo-rollouts --create-namespace \
  --set dashboard.enabled=false
