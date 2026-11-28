# FoodHub: detailed architecture

## 1. AWS cloud and VPC network

```mermaid
flowchart TB
  User[User browser] -->|HTTP :80| IGW[Internet Gateway]
  subgraph VPC["VPC 10.0.0.0/16, ap-south-1"]
    subgraph AZa["AZ ap-south-1a"]
      PUBA["Public subnet 10.0.0.0/24: ALB node, NAT Gateway"]
      PRIVA["Private subnet 10.0.10.0/24: EKS Spot nodes"]
    end
    subgraph AZb["AZ ap-south-1b"]
      PUBB["Public subnet 10.0.1.0/24: ALB node"]
      PRIVB["Private subnet 10.0.11.0/24: EKS Spot nodes"]
    end
    IGW --> PUBA
    IGW --> PUBB
    PUBA -->|target-type ip| PRIVA
    PUBB -->|target-type ip| PRIVB
    PRIVA -->|outbound via the single NAT| PUBA
    PRIVB -->|outbound via the single NAT| PUBA
  end
  CP[EKS control plane, AWS managed] --- PRIVA
  CP --- PRIVB
  PRIVA -->|image pull| ECR[(ECR)]
  PRIVA -->|ESO via IRSA| SM[Secrets Manager]
  EBS[(EBS gp3 volumes)] --- PRIVA
  S3[(S3 Terraform state, locked)]
```

Not used: Route 53, CloudFront, RDS, ECS. One NAT gateway is a single point of failure, accepted for cost.

## 2. Three-tier application

```mermaid
flowchart LR
  B[Browser] --> ING[ALB Ingress]
  subgraph T1[Tier 1: presentation]
    FE[nginx + React static files]
  end
  subgraph T2[Tier 2: services, Spring Boot]
    US[user-service: register, login, issues JWT]
    MS[menu-service: menu items]
    OS[order-service: orders]
  end
  subgraph T3[Tier 3: data]
    DB[(MongoDB: users, menuItems, orders)]
  end
  ING --> FE
  FE -->|/api/auth| US
  FE -->|/api/menu| MS
  FE -->|/api/orders| OS
  US --> DB
  MS --> DB
  OS --> DB
  JWT[(Shared JWT secret)] -.-> US
  JWT -.-> MS
  JWT -.-> OS
```

Services never call each other. menu-service and order-service verify the JWT issued by user-service using the same secret. No API gateway, no cache.

## 3. CI/CD and DevSecOps (GitHub Actions + ArgoCD)

```mermaid
flowchart LR
  Dev[Developer] -->|push or PR| GH[GitHub]
  GH --> T[Tests: Maven, npm lint and build]
  GH --> GL[Gitleaks secret scan]
  GH --> SC[SonarCloud code quality]
  GH --> TF[Terraform PRs: fmt, validate, Checkov]
  T --> B[Docker build]
  B --> TR[Trivy image scan HIGH and CRITICAL]
  TR -->|main only, OIDC role, no stored keys| ECR[(ECR, tag = commit SHA)]
  ECR --> UT[update-tags job]
  UT -->|commits new tag to helm values| GH
  GH -->|ArgoCD polls Git| ARGO[ArgoCD in EKS]
  ARGO --> RO[Argo Rollouts canary]
  DEP[Dependabot] -->|update PRs| GH
```

CI never runs kubectl and holds no cluster credentials. Pull requests skip the ECR push and tag commit.

## 4. Kubernetes (EKS)

```mermaid
flowchart TB
  ALB[AWS ALB] --> ING[Ingress, AWS Load Balancer Controller]
  subgraph NS[namespace foodhub]
    ING --> SVCF[Service frontend, plain Deployment]
    SVCF --> FEP[frontend pods]
    FEP --> SVCU[Service user-service]
    FEP --> SVCM[Service menu-service]
    FEP --> SVCO[Service order-service]
    SVCU --> RU[Rollout: user pods]
    SVCM --> RM[Rollout: menu pods]
    SVCO --> RO[Rollout: order pods]
    HPA[HPA, CPU 60 percent, 2 to 4 pods] --> RU
    HPA --> RM
    HPA --> RO
    RU --> MDB[(MongoDB StatefulSet + PVC gp3)]
    RM --> MDB
    RO --> MDB
    SEC[Secret foodhub-jwt] -.-> RU
    SEC -.-> RM
    SEC -.-> RO
  end
  ESO[External Secrets Operator] -->|creates| SEC
  SM[AWS Secrets Manager] --> ESO
  CA[Cluster Autoscaler] --> NG[Spot node group, 2 to 5 nodes]
  NP[NetworkPolicies: default deny + allow rules, applied manually in Phase 8]
  KY[Kyverno policies, Audit mode, applied manually in Phase 8]
```

Config comes from env vars in Helm values, so there are no ConfigMaps. Pods run non-root with dropped capabilities.

## 5. Monitoring, logging and observability

```mermaid
flowchart LR
  subgraph Cluster[EKS cluster]
    SVC[Service /metrics endpoints] --> SM[ServiceMonitors]
    SM --> PROM[Prometheus]
    NE[node-exporter and kube-state-metrics] --> PROM
    PODS[Pod logs] --> ALLOY[Alloy DaemonSet] --> LOKI[Loki]
    PROM --> AM[Alertmanager]
    PROM --> GRAF[Grafana]
    LOKI --> GRAF
  end
  AM -->|webhook from Secrets Manager via ESO| SLACK[Slack]
```

Metrics and logs for the services and nodes go to Prometheus and Loki, not CloudWatch. MongoDB has no exporter, so database metrics aren't collected.
