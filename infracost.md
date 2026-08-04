# 🚀 Terraform DevSecOps Pipeline with GitHub Actions, Infracost & AWS

> **Enterprise-grade Terraform DevSecOps Pipeline** demonstrating Security, Compliance, FinOps, Governance, and Infrastructure Automation using GitHub Actions and AWS.

---

# 📌 Project Overview

This project demonstrates how modern DevSecOps teams deploy Infrastructure as Code (IaC) securely and efficiently.

Instead of simply running:

```bash
terraform apply
```

this pipeline introduces multiple quality gates before infrastructure reaches production.

Every Terraform change is validated for:

- ✅ Secrets
- ✅ Best Practices
- ✅ Security
- ✅ Compliance
- ✅ Cost
- ✅ Policies
- ✅ Governance

before deployment.

---

# 🏗 Architecture

```text
                    GitHub Repository
                           │
                  GitHub Actions (OIDC)
                           │
     ┌─────────────────────────────────────────┐
     │ Stage 1  GitLeaks                       │
     │ Stage 2  terraform fmt                  │
     │ Stage 3  TFLint                         │
     │ Stage 4  Checkov                        │
     │ Stage 5  tfsec                          │
     │ Stage 6  Terrascan                      │
     │ Stage 7  Infracost                      │
     │ Stage 8  Terraform Validate             │
     │ Stage 9  Terraform Plan                 │
     │ Stage10  OPA Policy                     │
     │ Stage11  Manual Approval                │
     │ Stage12  Terraform Apply                │
     └─────────────────────────────────────────┘
                           │
                    AWS Infrastructure
                           │
        ┌────────────────────────────────────┐
        │ EC2                               │
        │ VPC                               │
        │ IAM                               │
        │ Security Groups                   │
        │ S3 Backend                        │
        │ DynamoDB Lock                     │
        └────────────────────────────────────┘
```

---

# 🎯 Objectives

The goal of this project is to demonstrate how enterprise organizations build secure Infrastructure as Code pipelines using:

- Terraform
- GitHub Actions
- AWS
- DevSecOps
- FinOps
- Policy as Code
- Infrastructure Security

---

# 🛠 Technology Stack

## Cloud

- AWS

---

## Infrastructure as Code

- Terraform

---

## CI/CD

- GitHub Actions

---

## Security

- GitLeaks
- Checkov
- tfsec
- Terrascan

---

## Cost Management

- Infracost

---

## Policy as Code

- Open Policy Agent (OPA)
- Conftest

---

## Backend

- S3 Remote Backend
- DynamoDB State Locking

---

## Authentication

- GitHub OIDC
- IAM Roles

---

# 📂 Project Structure

```text
terraform-devsecops-demo/

│
├── .github/
│   └── workflows/
│       └── terraform.yml
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── backend.tf
│   └── versions.tf
│
├── modules/
│   ├── ec2/
│   ├── vpc/
│   ├── iam/
│   └── security-group/
│
├── environments/
│   ├── dev/
│   └── prod/
│
├── policy/
│   ├── ec2.rego
│   ├── tags.rego
│   └── encryption.rego
│
├── screenshots/
│
└── README.md
```

---

# ☁ AWS Infrastructure

The Terraform code provisions:

- VPC
- Public Subnet
- Internet Gateway
- Route Tables
- Security Groups
- IAM Role
- EC2 Instance

---

# 🔐 Terraform Backend

Terraform Remote State

- Amazon S3
- DynamoDB Locking

Benefits

- Shared State
- State Locking
- Versioning
- Team Collaboration

---

# 🔑 Authentication

GitHub Actions uses

## OIDC Authentication

No AWS Access Keys are stored inside GitHub Secrets.

Authentication Flow

```text
GitHub Actions

↓

OIDC Token

↓

AWS IAM Role

↓

Temporary Credentials

↓

Terraform
```

---

# 🚦 CI/CD Pipeline

---

## Stage 1

# GitLeaks

Purpose

Secret Detection

Scans

- AWS Keys
- GitHub Tokens
- Passwords
- API Keys
- Private Keys

Pipeline fails immediately if secrets are detected.

---

## Stage 2

# Terraform fmt

Checks formatting consistency.

```bash
terraform fmt -check -recursive
```

Ensures

- Readable code
- Standard formatting

---

## Stage 3

# TFLint

Terraform Best Practices

Detects

- Deprecated Resources
- Unused Variables
- Invalid Instance Types
- AWS Provider Issues

---

## Stage 4

# Checkov

Infrastructure Security

Checks

- Public S3 Buckets
- Encryption
- IAM Wildcards
- Open Security Groups
- Missing Tags
- CIS Benchmark Violations

---

## Stage 5

# tfsec

Terraform Security Scanner

Detects

- Open Security Groups
- Missing Encryption
- Weak IAM Policies
- Logging Issues
- Security Misconfigurations

---

## Stage 6

# Terrascan

Policy Validation

Supports

- AWS
- Azure
- GCP
- Kubernetes

Validates

- Security
- Compliance
- Governance

---

## Stage 7

# Infracost

Infrastructure Cost Estimation

Instead of waiting for the monthly cloud invoice...

Developers know infrastructure cost before deployment.

Example

Current Cost

```text
$45/month
```

New Cost

```text
$78/month
```

Difference

```text
+$33/month
```

Benefits

- PR Cost Estimates
- Cost Diff
- Monthly Forecast
- Multi-cloud Support

---

## Stage 8

# Terraform Validate

Checks

- Syntax
- Variables
- Modules

Command

```bash
terraform validate
```

---

## Stage 9

# Terraform Plan

Creates

```bash
terraform plan
```

Produces

```text
tfplan
```

Artifact is uploaded for approval.

---

## Stage 10

# Open Policy Agent (OPA)

Policy as Code

Example Policies

### EC2 Size Restriction

```text
Only t3.micro and t3.small allowed
```

---

### Mandatory Tags

```text
Environment

Owner

Project
```

---

### S3 Encryption

Every bucket must enable

AES256

or

KMS Encryption

---

## Stage 11

# Manual Approval

Production deployment requires

GitHub Environment Approval

Approved Reviewer

↓

Terraform Apply

---

## Stage 12

# Terraform Apply

Infrastructure deployment

```bash
terraform apply tfplan
```

Deploys

- EC2
- VPC
- Security Groups
- IAM
- Networking

---

# 🔐 Security Layers

✔ GitLeaks

✔ TFLint

✔ Checkov

✔ tfsec

✔ Terrascan

✔ OPA

---

# 💰 FinOps

Infracost provides

- Monthly Cost
- Resource Cost Breakdown
- Cost Diff
- Pull Request Comments
- Multi-cloud Pricing

---

# 📊 Demo Scenario

## Step 1

Deploy

```text
EC2

t3.micro
```

Monthly Cost

```text
$12
```

---

## Step 2

Modify Terraform

```text
t3.micro

↓

m7i.2xlarge
```

---

## Step 3

Create Pull Request

Pipeline executes

- GitLeaks
- TFLint
- Checkov
- tfsec
- Terrascan
- Infracost

---

## Step 4

Infracost reports

```text
Current

$12/month

New

$286/month

Increase

+$274
```

---

## Step 5

OPA blocks deployment

Reason

```text
Instance type exceeds organization policy
```

---

## Step 6

Developer changes

```text
m7i.2xlarge

↓

t3.small
```

Pipeline passes.

---

## Step 7

Manual Approval

Reviewer approves production deployment.

---

## Step 8

Terraform Apply

Infrastructure successfully deployed.

---

# 📈 Enterprise Benefits

✅ Shift Left Security

✅ Shift Left FinOps

✅ Infrastructure Governance

✅ Policy as Code

✅ Cost Visibility

✅ Compliance

✅ Infrastructure Automation

✅ Audit Trail

✅ Production Approvals

---

# 🚀 Future Enhancements

- AWS Config
- CloudTrail
- AWS Security Hub
- Amazon Inspector
- Terraform Cloud
- Atlantis
- Drift Detection
- Slack Notifications
- Microsoft Teams Notifications
- SARIF Reports
- SonarQube Integration
- ServiceNow Change Management
- Multi-Environment Promotion
- Amazon EKS Deployment
- Azure AKS Deployment

---

# 📚 Learning Outcomes

By completing this project, you'll gain hands-on experience with:

- GitHub Actions
- Terraform
- AWS
- Infrastructure as Code
- GitHub OIDC Authentication
- Terraform Remote State
- DevSecOps
- FinOps
- Infrastructure Security
- Policy as Code
- Infrastructure Governance
- Enterprise CI/CD
- Cost Optimization
- Compliance Automation

---

# ⭐ If you found this project helpful

Give this repository a ⭐ and feel free to fork it, experiment with it, and use it as a reference for building enterprise-grade Terraform DevSecOps pipelines.
