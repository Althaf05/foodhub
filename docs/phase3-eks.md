# Phase 3: EKS

- ECR repos live in envs/dev (force_delete, so destroy removes them; CI re-pushes).
- Nodes: Spot m7i-flex.large / c7i-flex.large (free-plan-eligible types only).
- Session routine: terraform apply; aws eks update-kubeconfig --name foodhub-dev;
  kubectl apply -f k8s/bootstrap/storageclass-gp3.yaml; k8s/bootstrap/metrics-server.sh
- End of session: terraform destroy, then verify no cluster, NAT, EIP or volumes.
