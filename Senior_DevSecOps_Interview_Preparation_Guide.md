# Senior DevSecOps Engineer Interview Preparation Guide

## Job Focus

-   AWS EKS Security
-   Kubernetes Security
-   DevSecOps
-   Terraform & Ansible
-   GitHub / GitLab
-   Argo CD & Argo Workflows
-   Python Automation
-   Vulnerability Management
-   WAF, Istio, Zero Trust
-   CI/CD Security

------------------------------------------------------------------------

# Round 1 -- Kubernetes Security

## Q1. How do you secure an AWS EKS cluster?

**Answer**

Use a defense-in-depth approach:

-   IAM + OIDC authentication
-   Kubernetes RBAC with least privilege
-   IRSA for Pods
-   Pod Security Standards (Restricted)
-   Network Policies
-   Istio mTLS
-   AWS Secrets Manager / External Secrets
-   Image scanning (Trivy/Grype)
-   CloudTrail, GuardDuty, Prometheus, Grafana

------------------------------------------------------------------------

## Q2. RBAC vs IAM

  IAM                      RBAC
  ------------------------ -------------------------------
  Controls AWS resources   Controls Kubernetes resources
  Authenticates users      Authorizes Kubernetes actions
  EC2, S3, EKS API         Pods, Secrets, Deployments

------------------------------------------------------------------------

## Q3. What is IRSA?

IRSA (IAM Roles for Service Accounts) allows Pods to assume AWS IAM
roles using OIDC without storing static AWS credentials.

Flow:

    Pod
     ↓
    Service Account
     ↓
    OIDC Token
     ↓
    AWS STS
     ↓
    Temporary Credentials

------------------------------------------------------------------------

## Q4. Kubernetes Network Policies

Restrict Pod-to-Pod communication using Zero Trust principles.

Example:

    Frontend
       ↓
    Backend
       ↓
    Database

Frontend cannot directly access the Database.

------------------------------------------------------------------------

## Q5. Pod Security Standards

Levels:

-   Privileged
-   Baseline
-   Restricted (recommended)

Enforce: - Non-root containers - Read-only filesystem - Drop Linux
capabilities - No privileged Pods

------------------------------------------------------------------------

# Round 2 -- DevSecOps

## Q6. Secure CI/CD Pipeline

    Checkout
       ↓
    Secrets Scan (Gitleaks)
       ↓
    SAST (Semgrep)
       ↓
    SonarQube
       ↓
    Unit Tests
       ↓
    Build
       ↓
    Dependency Scan
       ↓
    Trivy FS Scan
       ↓
    Docker Build
       ↓
    Image Scan
       ↓
    SBOM
       ↓
    Cosign Sign
       ↓
    Push to ECR
       ↓
    Argo CD Deploy

------------------------------------------------------------------------

## Q7. Trivy vs Grype

### Trivy

-   Container scanning
-   Filesystem scanning
-   IaC scanning
-   Secret scanning
-   Misconfiguration scanning

### Grype

-   CVE detection
-   Uses Syft SBOM
-   Excellent vulnerability matching

------------------------------------------------------------------------

## Q8. What happens if Trivy finds Critical vulnerabilities?

-   Fail pipeline
-   Notify developer
-   Upgrade dependencies
-   Rebuild image
-   Re-scan
-   Deploy only after passing policy

------------------------------------------------------------------------

## Q9. What is an SBOM?

Software Bill of Materials.

Contains: - Packages - Libraries - Versions - Licenses

Typical flow:

    Application
       ↓
    Syft
       ↓
    SBOM
       ↓
    Grype

------------------------------------------------------------------------

# Round 3 -- Terraform

## Q10. Terraform Best Practices

Structure:

    modules/
      vpc/
      eks/
      iam/
      alb/
      rds/

    environments/
      dev/
      qa/
      prod/

Use: - Remote backend (S3) - DynamoDB locking - Modular design

------------------------------------------------------------------------

## Q11. Terraform State Best Practices

-   Store remotely
-   Enable encryption
-   Enable versioning
-   Least-privilege IAM
-   Remote state outputs

------------------------------------------------------------------------

## Q12. Drift Detection

    terraform plan
    Review
    Approve
    terraform apply

------------------------------------------------------------------------

# Round 4 -- AWS Security

## Q13. How do you secure AWS?

-   IAM least privilege
-   GuardDuty
-   CloudTrail
-   AWS Config
-   Security Hub
-   KMS
-   Secrets Manager
-   Private subnets
-   WAF
-   Shield
-   CloudWatch

------------------------------------------------------------------------

## Q14. Security Groups vs NACL

  Security Groups   NACL
  ----------------- --------------
  Stateful          Stateless
  Instance level    Subnet level
  Allow only        Allow & Deny

------------------------------------------------------------------------

## Q15. Explain GitHub OIDC

    GitHub Actions
          ↓
    OIDC Token
          ↓
    AWS STS
          ↓
    Temporary Role
          ↓
    Deploy

No long-lived AWS keys.

------------------------------------------------------------------------

# Round 5 -- GitOps

## Q16. What is GitOps?

    Developer
        ↓
    Git Push
        ↓
    Argo CD
        ↓
    Kubernetes Sync

Git is the single source of truth.

------------------------------------------------------------------------

## Q17. Argo CD vs Argo Workflows

  Argo CD               Argo Workflows
  --------------------- ---------------------------
  GitOps Deployments    Automation Pipelines
  Continuous Delivery   Jobs & Security Workflows

------------------------------------------------------------------------

# Round 6 -- Python Automation

## Q18. Python Security Automation

Examples:

-   Vulnerability parsing
-   Slack notifications
-   GitHub API automation
-   EBS snapshot cleanup
-   Terraform validation
-   Security reporting

------------------------------------------------------------------------

## Q19. Automated Container Patching

    Base Image Updated
            ↓
    Webhook
            ↓
    GitHub Actions
            ↓
    Docker Rebuild
            ↓
    Trivy Scan
            ↓
    SBOM
            ↓
    Cosign
            ↓
    Push to ECR
            ↓
    Argo CD Sync

------------------------------------------------------------------------

# Round 7 -- Istio

## Q20. Why Istio?

-   mTLS
-   Traffic Management
-   Canary Releases
-   Authorization
-   Observability
-   Zero Trust

------------------------------------------------------------------------

# Leadership Questions

## Q21. Describe a Production Incident

Use STAR:

-   Situation
-   Task
-   Action
-   Result

Example: - Investigated Prometheus metrics. - Found CPU throttling. -
Tuned requests/limits. - Restored service. - Added monitoring alerts.

------------------------------------------------------------------------

## Q22. Vulnerability Prioritization

Prioritize based on:

-   CVSS
-   Exploitability
-   Internet exposure
-   Runtime usage
-   Business impact
-   Patch availability

------------------------------------------------------------------------

# Scenario Questions

## Scenario 1: Trivy Reports 200 Vulnerabilities

-   Categorize severity
-   Remove unused packages
-   Upgrade base image
-   Upgrade dependencies
-   Rebuild
-   Re-scan

------------------------------------------------------------------------

## Scenario 2: Compromised Pod

-   Isolate Pod
-   Collect logs
-   Review audit logs
-   Rotate secrets
-   Redeploy trusted image
-   Perform RCA

------------------------------------------------------------------------

## Scenario 3: Zero Trust Kubernetes

-   Least-privilege RBAC
-   IRSA
-   Istio mTLS
-   Network Policies
-   Pod Security Standards
-   Continuous monitoring

------------------------------------------------------------------------

# Final Interview Tips

Focus on: - Architecture decisions - Security trade-offs - Production
incidents - Automation examples - Terraform design - Kubernetes
troubleshooting - CI/CD security - Vulnerability remediation -
Leadership and mentoring

Practice explaining **why** you chose a design, not just **how** you
implemented it.
