# Enterprise Terraform CI/CD with GitHub Actions, AWS OIDC, GitOps, Security & Observability

An enterprise-grade, Git-driven infrastructure delivery workflow using GitHub, GitHub Actions, Terraform, AWS, OIDC, S3 remote state, security scanning, policy-as-code, semantic versioning, controlled environment promotion, GitOps, observability, and drift detection.

---

## 1. Architecture Overview

```text
Developer
   |
   v
Feature Branch
   |
   v
Pull Request
   |
   +--> Terraform fmt / validate
   +--> TFLint
   +--> Checkov
   +--> Trivy IaC
   +--> Gitleaks
   +--> OPA / Conftest
   +--> Terraform Plan
   |
   v
Code Review
   |
   v
Merge to main
   |
   v
Semantic Version Tag
   |
   +-------------------------------+
   |                               |
   v                               v
Terraform Apply                 GitOps
Dev -> Staging -> Prod          Argo CD
   |                               |
   v                               v
AWS Infrastructure             Kubernetes / EKS
   |
   +--> VPC
   +--> EKS
   +--> IAM
   +--> RDS
   +--> S3
   +--> ALB
   +--> Supporting Services
   |
   v
Observability
Prometheus / Grafana / CloudWatch / Datadog
   |
   v
Scheduled Drift Detection
```

---

# 2. Enterprise Technology Stack

| Layer | Technology |
|---|---|
| Source Control | GitHub |
| CI/CD | GitHub Actions |
| Infrastructure | Terraform |
| Cloud | AWS |
| Authentication | GitHub OIDC + AWS IAM |
| Remote State | Amazon S3 |
| State Protection | S3 encryption + versioning |
| Security | Checkov + Trivy + Gitleaks |
| Quality | Terraform Validate + TFLint |
| Policy | OPA / Conftest |
| Application GitOps | Argo CD |
| Kubernetes | Amazon EKS |
| Metrics | Prometheus |
| Dashboards | Grafana |
| AWS Monitoring | CloudWatch |
| APM / Observability | Datadog |
| Versioning | Git tags + Semantic Versioning |
| Promotion | Dev -> Staging -> Production |
| Governance | PR review + protected branches + approvals |
| Operations | Scheduled Terraform drift detection |

---

# 3. Prerequisites

Install locally:

```bash
git --version
terraform version
aws --version
kubectl version --client
helm version
docker --version
```

Optional security tools:

```bash
tflint --version
checkov --version
trivy --version
gitleaks version
conftest --version
```

You also need:

- AWS account
- GitHub repository
- AWS IAM administrative/bootstrap access
- Terraform
- GitHub Actions enabled
- Amazon EKS if application GitOps is required
- Prometheus/Grafana if Kubernetes observability is required

---

# 4. Recommended Repository Structure

```text
enterprise-terraform/
|
+-- .github/
|   +-- workflows/
|       +-- terraform-pr.yml
|       +-- terraform-dev.yml
|       +-- terraform-staging.yml
|       +-- terraform-prod.yml
|       +-- terraform-drift.yml
|
+-- modules/
|   +-- vpc/
|   +-- eks/
|   +-- iam/
|   +-- rds/
|   +-- s3/
|   +-- alb/
|
+-- environments/
|   +-- dev/
|   |   +-- backend.tf
|   |   +-- providers.tf
|   |   +-- main.tf
|   |   +-- variables.tf
|   |   +-- outputs.tf
|   |   +-- terraform.tfvars.example
|   |
|   +-- staging/
|   |
|   +-- prod/
|
+-- policies/
|   +-- conftest/
|       +-- terraform.rego
|
+-- tests/
|
+-- .gitignore
+-- .terraform-version
+-- .tflint.hcl
+-- README.md
+-- CHANGELOG.md
```

Keep environment state separate. Do not use one Terraform state file for Dev, Staging, and Production.

---

# 5. Step 1 - Create the GitHub Repository

Create a private repository:

```text
enterprise-terraform
```

Clone it:

```bash
git clone git@github.com:ORG/enterprise-terraform.git
cd enterprise-terraform
```

Configure Git:

```bash
git config user.name "Your Name"
git config user.email "your-email@example.com"
```

Create the initial branch:

```bash
git checkout -b main
```

---

# 6. Step 2 - Create the Terraform Directory Structure

```bash
mkdir -p modules/{vpc,eks,iam,rds,s3,alb}
mkdir -p environments/{dev,staging,prod}
mkdir -p policies/conftest
mkdir -p tests
mkdir -p .github/workflows
```

Create the basic files:

```bash
touch .terraform-version
touch .tflint.hcl
touch CHANGELOG.md
touch .gitignore
```

Pin the Terraform version:

```text
1.9.8
```

Use the version approved by your organization.

---

# 7. Step 3 - Build the Terraform Bootstrap Layer

The Terraform backend cannot safely depend on the same state it is storing.

Create a separate bootstrap stack for:

- S3 Terraform state bucket
- S3 versioning
- S3 encryption
- Bucket public-access blocking
- Bucket policy
- Optional KMS key

Example:

```text
bootstrap/
+-- main.tf
+-- variables.tf
+-- outputs.tf
```

Example S3 state configuration:

```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

For stricter enterprise environments, use a customer-managed KMS key and appropriate key policies.

---

# 8. Step 4 - Configure Terraform Remote State

Example:

```hcl
terraform {
  backend "s3" {
    bucket       = "company-terraform-state"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

Use separate keys:

```text
dev/terraform.tfstate
staging/terraform.tfstate
prod/terraform.tfstate
```

Do not commit `.tfstate` files to Git.

---

# 9. Step 5 - Configure AWS Provider

Example:

```hcl
terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Environment = var.environment
      Repository  = "enterprise-terraform"
    }
  }
}
```

Pin provider versions according to your organization's release policy.

---

# 10. Step 6 - Build Reusable Terraform Modules

Example module:

```text
modules/vpc/
+-- main.tf
+-- variables.tf
+-- outputs.tf
```

Use modules for:

- VPC
- Subnets
- NAT
- Security Groups
- EKS
- IAM
- RDS
- S3
- ALB

Environment configuration should consume these modules instead of duplicating resource definitions.

Example:

```hcl
module "vpc" {
  source = "../../modules/vpc"

  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}
```

---

# 11. Step 7 - Create Environment Isolation

Each environment should have its own configuration and state.

```text
environments/
|
+-- dev/
|   +-- backend.tf
|   +-- providers.tf
|   +-- main.tf
|   +-- variables.tf
|
+-- staging/
|
+-- prod/
```

Recommended promotion:

```text
DEV
 |
 v
STAGING
 |
 v
PRODUCTION
```

Production should never be changed directly from a developer laptop.

---

# 12. Step 8 - Configure GitHub OIDC

Create an AWS IAM OIDC provider for GitHub.

Trust should be restricted to the required GitHub organization/repository and branch/environment.

Conceptually:

```text
GitHub Actions
      |
      | OIDC token
      v
AWS STS
      |
      | AssumeRoleWithWebIdentity
      v
Terraform IAM Role
      |
      v
AWS APIs
```

Use separate roles:

```text
terraform-dev-role
terraform-staging-role
terraform-prod-role
```

Production should have the strongest restrictions.

Do not store:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

for Terraform authentication when OIDC is available.

---

# 13. Step 9 - Configure GitHub Environments

Create:

```text
dev
staging
production
```

Configure production with:

- Required reviewers
- Deployment protection
- Restricted branch/tag deployment
- Environment-specific AWS role
- Environment-specific secrets only when genuinely required

Prefer GitHub OIDC over static cloud credentials.

---

# 14. Step 10 - Terraform Pull Request Workflow

Every Pull Request should perform validation before merge.

Pipeline:

```text
Pull Request
     |
     +--> Checkout
     |
     +--> Terraform fmt
     |
     +--> Terraform init
     |
     +--> Terraform validate
     |
     +--> TFLint
     |
     +--> Checkov
     |
     +--> Trivy
     |
     +--> Gitleaks
     |
     +--> OPA / Conftest
     |
     +--> Terraform plan
     |
     v
Pull Request Review
```

Example:

```yaml
name: Terraform PR

on:
  pull_request:
    branches:
      - main

permissions:
  contents: read
  pull-requests: write

jobs:
  terraform:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.8

      - name: Terraform Format
        run: terraform fmt -check -recursive

      - name: Terraform Init
        working-directory: environments/dev
        run: terraform init

      - name: Terraform Validate
        working-directory: environments/dev
        run: terraform validate

      - name: TFLint
        uses: terraform-linters/setup-tflint@v4

      - name: Checkov
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: .

      - name: Trivy IaC
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: config
          scan-ref: .

      - name: Gitleaks
        uses: gitleaks/gitleaks-action@v2

      - name: Terraform Plan
        working-directory: environments/dev
        run: terraform plan -out=tfplan
```

Review and pin third-party GitHub Actions to approved versions or commit SHAs according to enterprise policy.

---

# 15. Step 11 - Add Terraform Quality Gates

Minimum checks:

```bash
terraform fmt -check -recursive
terraform init
terraform validate
```

Add TFLint:

```bash
tflint --init
tflint
```

The pipeline should fail when mandatory quality checks fail.

---

# 16. Step 12 - Add Checkov

Checkov validates Terraform against security best practices.

Example:

```bash
checkov -d .
```

Typical checks include:

- Public S3 buckets
- Unrestricted security groups
- Missing encryption
- Weak IAM policies
- Public databases
- Missing logging
- Missing security controls

Use organization-specific suppressions only when there is a documented reason.

---

# 17. Step 13 - Add Trivy IaC Scanning

Run:

```bash
trivy config .
```

This provides another IaC security layer.

Example pipeline:

```yaml
- name: Trivy IaC Scan
  uses: aquasecurity/trivy-action@master
  with:
    scan-type: config
    scan-ref: .
    severity: HIGH,CRITICAL
    exit-code: 1
```

Pin the action version according to your security policy.

---

# 18. Step 14 - Add Gitleaks

Run secret detection before infrastructure changes are merged:

```bash
gitleaks detect --source . --redact
```

The pipeline should block commits containing:

- AWS keys
- API tokens
- passwords
- private keys
- cloud credentials
- application secrets

Never put secrets in:

```text
*.tf
*.tfvars
terraform.tfstate
Git history
```

Use AWS Secrets Manager, SSM Parameter Store, or another approved secret-management system.

---

# 19. Step 15 - Add OPA / Conftest

Example policy:

```rego
package terraform

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  not resource.change.after.server_side_encryption_configuration

  msg := "S3 buckets must use encryption"
}
```

Run:

```bash
conftest test terraform-plan.json
```

Policy-as-code allows organizations to enforce requirements such as:

```text
No public S3
No unrestricted SSH
Encryption required
Required tags
Approved regions only
Approved instance types
Mandatory logging
Required backup configuration
```

---

# 20. Step 16 - Generate Terraform Plan

Create a plan:

```bash
terraform plan -out=tfplan
```

Convert it to JSON when policy validation requires machine-readable input:

```bash
terraform show -json tfplan > terraform-plan.json
```

Use the plan as an artifact.

The important principle is:

> Review the exact infrastructure change before applying it.

---

# 21. Step 17 - Code Review Governance

Protect `main`.

Recommended rules:

```text
Require pull request
Require 1-2 reviewers
Require successful CI checks
Require resolved conversations
Restrict direct pushes
Require CODEOWNERS approval
```

Example ownership:

```text
*.tf              @platform-team
modules/          @platform-team
environments/prod @cloud-platform-team
```

---

# 22. Step 18 - Merge to Main

After approval:

```text
Feature Branch
      |
      v
Pull Request
      |
      v
Security + Quality
      |
      v
Approval
      |
      v
Merge main
```

`main` represents the approved infrastructure source.

---

# 23. Step 19 - Semantic Versioning

Use:

```text
MAJOR.MINOR.PATCH
```

Examples:

```text
v1.0.0
v1.1.0
v1.1.1
v2.0.0
```

Example:

```bash
git tag -a v1.2.0 -m "Add production EKS infrastructure"
git push origin v1.2.0
```

Recommended meaning:

```text
MAJOR = breaking infrastructure/module change
MINOR = new capability
PATCH = bug/security/non-breaking fix
```

---

# 24. Step 20 - Dev Deployment

A release can first deploy to Dev:

```text
Tag
 |
 v
Terraform Init
 |
 v
Terraform Plan
 |
 v
Terraform Apply
 |
 v
AWS DEV
```

Example:

```bash
terraform apply -auto-approve tfplan
```

For enterprise production workflows, avoid using `-auto-approve` unless the approval model is implemented outside Terraform and the exact reviewed plan is being applied.

---

# 25. Step 21 - Staging Promotion

After Dev validation:

```text
DEV
 |
 | tests
 v
STAGING
```

Run:

- Infrastructure validation
- Application integration tests
- Kubernetes validation
- Security checks
- Smoke tests

Then approve production.

---

# 26. Step 22 - Production Promotion

Production:

```text
STAGING
   |
   v
Production Approval
   |
   v
Terraform Plan
   |
   v
Reviewed Plan
   |
   v
Terraform Apply
   |
   v
AWS PRODUCTION
```

Production must use:

- Dedicated IAM role
- Restricted GitHub environment
- Required reviewers
- Protected production branch/tag
- Audit logs
- Terraform state protection

---

# 27. Step 23 - GitOps with Argo CD

Terraform should provision the platform.

Argo CD should manage Kubernetes applications.

Recommended separation:

```text
Terraform
   |
   +--> VPC
   +--> EKS
   +--> IAM
   +--> RDS
   +--> ALB
   +--> Supporting AWS Services
             |
             v
          Amazon EKS
             |
             v
          Argo CD
             |
             v
       Kubernetes Apps
```

Avoid using Terraform as the primary mechanism for continuously deploying application workloads when Argo CD is already responsible for application GitOps.

---

# 28. Step 24 - Observability

Infrastructure:

```text
AWS
 |
 +--> CloudWatch
 |
 +--> Datadog
 |
 +--> CloudTrail
```

Kubernetes:

```text
EKS
 |
 +--> Prometheus
 |
 +--> Grafana
 |
 +--> OpenTelemetry
 |
 +--> CloudWatch / Datadog
```

Monitor:

- CPU
- Memory
- Node health
- Pod health
- API server
- Deployment status
- Network errors
- Application latency
- Error rate
- AWS service health
- Infrastructure capacity

---

# 29. Step 25 - Terraform Drift Detection

Schedule a workflow:

```text
Daily / Scheduled
       |
       v
Terraform Init
       |
       v
Terraform Plan
       |
       v
Changes?
   /        \
 No          Yes
 |            |
 v            v
Success      Alert
              |
              +--> GitHub Issue
              +--> Slack / Email
              +--> Investigation
```

Example:

```yaml
name: Terraform Drift Detection

on:
  schedule:
    - cron: "0 2 * * *"
  workflow_dispatch:

permissions:
  contents: read
  id-token: write

jobs:
  drift:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.8

      - name: Terraform Init
        working-directory: environments/prod
        run: terraform init

      - name: Terraform Plan
        working-directory: environments/prod
        run: terraform plan -detailed-exitcode
```

Interpret the exit codes:

```text
0 = No changes
1 = Error
2 = Changes detected
```

Treat exit code `2` as drift requiring investigation.

Do not automatically overwrite production changes without understanding why the drift occurred.

---

# 30. Step 26 - Auditability

Every production infrastructure change should be traceable:

```text
Developer
   |
   v
Git Commit
   |
   v
Pull Request
   |
   v
Review
   |
   v
Terraform Plan
   |
   v
Release Tag
   |
   v
GitHub Environment Approval
   |
   v
Terraform Apply
   |
   v
AWS CloudTrail
```

Example:

```text
Production
   |
   +-- Release: v1.4.0
   +-- Commit: abc1234
   +-- PR: #142
   +-- Terraform Plan
   +-- Approved by Platform Team
   +-- Applied by GitHub Actions
```

This is essential for enterprise auditability.

---

# 31. Recommended CI/CD Pipelines

Use separate workflows rather than one huge workflow.

```text
.github/workflows/

terraform-pr.yml
    |
    +-- Format
    +-- Validate
    +-- TFLint
    +-- Checkov
    +-- Trivy
    +-- Gitleaks
    +-- OPA
    +-- Plan

terraform-dev.yml
    |
    +-- Plan
    +-- Apply DEV
    +-- Smoke Test

terraform-staging.yml
    |
    +-- Plan
    +-- Apply STAGING
    +-- Integration Test

terraform-prod.yml
    |
    +-- Plan
    +-- Approval
    +-- Apply PROD

terraform-drift.yml
    |
    +-- Scheduled Plan
    +-- Detect Drift
    +-- Alert
```

This separation makes the workflow easier to maintain and audit.

---

# 32. Complete Enterprise Flow

```text
                         GITHUB
                            |
                     Feature Branch
                            |
                            v
                    Pull Request
                            |
             +--------------+--------------+
             |              |              |
             v              v              v
        Terraform       Security       Policy
         Quality        Scanning       Validation
             |              |              |
             |      +-------+-------+      |
             |      |       |       |      |
             |   Checkov  Trivy  Gitleaks  |
             |                              |
             +--------------+---------------+
                            |
                            v
                    Terraform Plan
                            |
                            v
                      Code Review
                            |
                            v
                       MAIN BRANCH
                            |
                            v
                    Semantic Version
                       v1.x.x
                            |
                            v
                    GitHub Actions
                            |
                            v
                     GitHub OIDC
                            |
                            v
                      AWS IAM Role
                            |
                            v
                     Terraform Apply
                            |
                +-----------+-----------+
                |           |           |
                v           v           v
               DEV       STAGING       PROD
                                      Approval
                                         |
                                         v
                                  AWS Production
                                         |
              +--------------------------+------------------+
              |              |             |                |
              v              v             v                v
             VPC            EKS           RDS              IAM
              |              |
              |              v
              |           Argo CD
              |              |
              |              v
              |       Kubernetes Apps
              |
              v
        Observability
              |
       +------+------+
       |      |      |
       v      v      v
 Prometheus Grafana CloudWatch
                       |
                       v
                    Datadog
                       |
                       v
               Drift Detection
                       |
                       v
                  Alert / Issue
```

---

# 33. Enterprise Security Principles

Follow these rules:

1. Never commit cloud credentials.
2. Prefer GitHub OIDC for AWS authentication.
3. Use least-privilege IAM roles.
4. Separate Dev, Staging, and Production accounts where possible.
5. Separate Terraform state by environment.
6. Encrypt Terraform state.
7. Enable S3 state versioning.
8. Protect production environments.
9. Require peer review for infrastructure changes.
10. Scan Terraform before merge.
11. Enforce policies using OPA/Conftest.
12. Use approved Terraform/provider versions.
13. Pin GitHub Actions versions according to organizational policy.
14. Store secrets in an approved secret manager.
15. Monitor Terraform drift.
16. Keep a complete Git-to-AWS audit trail.

---

# 34. Production Readiness Checklist

## Git

- [ ] Protected main branch
- [ ] CODEOWNERS
- [ ] Pull request reviews
- [ ] Semantic versioning
- [ ] Release tags
- [ ] Changelog

## Terraform

- [ ] Version pinned
- [ ] Provider versions controlled
- [ ] Reusable modules
- [ ] Separate environments
- [ ] Remote state
- [ ] State encryption
- [ ] State versioning
- [ ] State locking

## Security

- [ ] Gitleaks
- [ ] Checkov
- [ ] Trivy
- [ ] OPA/Conftest
- [ ] Least-privilege IAM
- [ ] GitHub OIDC
- [ ] Secrets Manager / approved secret store

## CI/CD

- [ ] Terraform fmt
- [ ] Terraform validate
- [ ] TFLint
- [ ] Security scans
- [ ] Terraform plan
- [ ] Plan artifact
- [ ] Environment approvals
- [ ] Production protection

## AWS

- [ ] Separate environments/accounts where appropriate
- [ ] CloudTrail
- [ ] CloudWatch
- [ ] Encryption
- [ ] IAM controls
- [ ] Network controls
- [ ] Backup strategy

## Kubernetes

- [ ] EKS
- [ ] RBAC
- [ ] Network Policies
- [ ] IRSA
- [ ] Secrets management
- [ ] Argo CD
- [ ] Prometheus
- [ ] Grafana

## Operations

- [ ] Drift detection
- [ ] Alerting
- [ ] Audit trail
- [ ] Incident process
- [ ] Rollback strategy
- [ ] Disaster recovery plan

---

# 35. Recommended End State

The final enterprise model should follow this principle:

```text
Git is the source of truth.

Terraform manages infrastructure.

GitHub Actions validates, secures, plans, and promotes infrastructure.

AWS OIDC provides short-lived authentication.

S3 stores protected Terraform state.

Checkov + Trivy + Gitleaks provide security gates.

TFLint + Terraform Validate provide quality gates.

OPA/Conftest enforces organizational policies.

Semantic versioning provides controlled infrastructure releases.

Dev -> Staging -> Production provides controlled promotion.

Argo CD manages Kubernetes application delivery.

Prometheus + Grafana + CloudWatch + Datadog provide observability.

Scheduled Terraform plans detect infrastructure drift.

Git + GitHub + AWS provide the complete audit trail.
```

---

## 36. Suggested Implementation Order

Implement this in phases rather than building everything at once.

### Phase 1 - Foundation

```text
GitHub
  -> Terraform
  -> AWS
  -> S3 Backend
  -> GitHub OIDC
```

### Phase 2 - CI Quality

```text
Terraform fmt
  -> Validate
  -> TFLint
  -> Plan
```

### Phase 3 - Security

```text
Gitleaks
  -> Checkov
  -> Trivy
  -> OPA/Conftest
```

### Phase 4 - Governance

```text
Protected Branch
  -> PR Review
  -> CODEOWNERS
  -> Environment Approval
  -> Semantic Versioning
```

### Phase 5 - Promotion

```text
DEV
  -> STAGING
  -> PRODUCTION
```

### Phase 6 - Platform

```text
Terraform
  -> VPC
  -> EKS
  -> IAM
  -> RDS
  -> Supporting AWS Services
```

### Phase 7 - GitOps

```text
EKS
  -> Argo CD
  -> Applications
```

### Phase 8 - Operations

```text
Prometheus
Grafana
CloudWatch
Datadog
Drift Detection
```

This phased implementation keeps the project manageable while still producing a complete enterprise-grade Terraform delivery platform.
