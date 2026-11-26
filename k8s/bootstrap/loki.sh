#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm upgrade --install loki grafana/loki -n monitoring -f k8s/monitoring/loki-values.yaml
