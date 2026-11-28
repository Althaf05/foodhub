# FoodHub Architecture

## Runtime

```mermaid
flowchart LR
  U[User browser] -->|HTTP| ALB[AWS ALB]
  ALB --> FE[frontend: nginx]
  FE -->|/api/auth| US[user-service]
  FE -->|/api/menu| MS[menu-service]
  FE -->|/api/orders| OS[order-service]
  US --> DB[(MongoDB StatefulSet, EBS gp3)]
  MS --> DB
  OS --> DB
  ESO[External Secrets Operator] -->|JWT_SECRET| US
  ESO --> MS
  ESO --> OS
  SM[AWS Secrets Manager] --> ESO
  subgraph EKS[EKS on Spot nodes, private subnets]
    FE
    US
    MS
    OS
    DB
    ESO
  end
```

## CI/CD and GitOps

```mermaid
flowchart LR
  Dev[Developer] -->|push / PR| GH[GitHub]
  GH --> CI[GitHub Actions: tests, Gitleaks, SonarCloud, Trivy]
  CI -->|OIDC, no stored keys| ECR[(ECR, SHA tags)]
  CI -->|commit image tag| GH
  GH -->|watch helm/| Argo[ArgoCD in cluster]
  Argo --> Roll[Argo Rollouts canary]
  ECR --> Roll
```

## Observability and platform

```mermaid
flowchart LR
  Svc[Services /metrics] --> P[Prometheus]
  P --> G[Grafana]
  P --> AM[Alertmanager] --> Slack
  Pods[Pod logs] --> A[Alloy] --> L[Loki] --> G
  HPA[HPA] --> Svc
  CA[Cluster Autoscaler] --> Nodes[Spot node group]
  NP[Network policies] --- Svc
  KY[Kyverno audit] --- Svc
```

## Infrastructure (Terraform)
- `bootstrap/`: S3 state bucket (versioned, encrypted, TLS-only).
- `envs/dev/`: VPC (2 public, 2 private subnets, one NAT), EKS, EBS CSI, IRSA roles, ECR, GitHub OIDC role.
- PR pipeline: fmt, validate, Checkov. Dependabot keeps dependencies current.
