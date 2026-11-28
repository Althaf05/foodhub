# FoodHub Runbook

## Session routine (cost: about $0.30-0.35/hour while the cluster is up)
1. `cd infra/terraform/envs/dev && terraform plan` (check ECR is not being replaced unless intended), then `terraform apply`.
2. After 5 min, check nodes launched:
   `aws autoscaling describe-scaling-activities --query "Activities[0:3].[StatusCode,StatusMessage]" --output text`
3. `aws eks update-kubeconfig --name foodhub-dev --region ap-south-1`
4. Run k8s/bootstrap scripts: storageclass-gp3.yaml, metrics-server.sh, argocd.sh, alb-controller.sh, argo-rollouts.sh, external-secrets.sh.
5. `kubectl create namespace foodhub`, then apply k8s/secrets/jwt.yaml and k8s/argocd/apps.yaml.
6. Optional: monitoring.sh, loki.sh, alloy.sh, k8s/secrets/slack.yaml, k8s/monitoring/foodhub-alerts.yaml, cluster-autoscaler.sh.

## Teardown
See docs/emergency-teardown.md. NEVER run a plain `terraform destroy` (it deletes ECR and the CI role).
Always confirm: no ALB, no `k8s-*` security groups, no orphan EBS volumes.

## Deployment flow (GitOps)
Push code -> CI (tests, Gitleaks, SonarCloud, Trivy) -> push images to ECR tagged by commit SHA via OIDC -> bot commits tag to helm/*/values.yaml -> ArgoCD syncs -> Argo Rollouts canary.
Always `git pull --rebase` before pushing (the bot commits to main).

## Troubleshooting
| Symptom | Cause / fix |
|---|---|
| Nodes never join; scaling activity Failed | Instance type not allowed on the account plan; use free-tier-eligible flex types |
| Pod ImagePullBackOff | Tag expired (ECR keeps 10 images) or ECR was replaced; list tags, rebuild via CI |
| App OutOfSync/Missing | CRD missing (e.g. ServiceMonitor without monitoring stack); chart renders it only if CRD exists |
| Frontend CrashLoopBackOff | nginx cannot resolve backend Services yet; fixes itself once they exist |
| Register/login returns 401 on bad input | Spring routes errors to /error; it must be permitted |
| Alert fires but no Slack message | Check state `suppressed`: info severity is inhibited by InfoInhibitor; use warning |
| ALB or VPC destroy hangs | Delete Ingress, wait for ALB, delete `k8s-*` security groups, delete orphan volumes |
| Bot push to main rejected (GH013) | Ruleset must not require PRs/status checks for the bot |
| Sonar fails on Dependabot PRs | Add SONAR_TOKEN to Dependabot secrets |

## Known gaps
- Mongo has no auth (network policies restrict access).
- Canary is replica-based (no ALB weighting, no metric-based abort).
- ECR KMS change merged but not applied.
- Cluster Autoscaler installed, scale-up not verified.
- Kyverno in Audit mode.
- Secrets Manager entries are created by CLI, not Terraform.
