#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  -f k8s/monitoring/kube-prometheus-stack-values.yaml
