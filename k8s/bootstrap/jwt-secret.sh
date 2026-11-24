#!/usr/bin/env bash
set -euo pipefail
kubectl create namespace foodhub --dry-run=client -o yaml | kubectl apply -f -
kubectl -n foodhub create secret generic foodhub-jwt \
  --from-literal=JWT_SECRET="$(openssl rand -base64 48 | tr -d '\n')" \
  --dry-run=client -o yaml | kubectl apply -f -
