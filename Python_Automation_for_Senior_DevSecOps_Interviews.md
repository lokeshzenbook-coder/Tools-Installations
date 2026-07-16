# Python Automation for Senior DevSecOps Engineer Interviews

> A collection of practical Python automation examples commonly
> implemented in enterprise DevSecOps environments. These examples
> demonstrate AWS automation, CI/CD integration, Infrastructure as Code
> validation, vulnerability management, GitHub automation, and team
> notifications.

------------------------------------------------------------------------

# Table of Contents

1.  AWS Resource Management
2.  EBS Snapshot Cleanup
3.  Trivy Vulnerability Report Parser
4.  Slack Notification Automation
5.  GitHub Pull Request Automation
6.  Terraform Validation Automation
7.  GitHub Actions Workflow Trigger
8.  Interview Tips

------------------------------------------------------------------------

# 1. AWS Resource Management (Stop Idle EC2 Instances)

## Objective

Automatically stop running non-production EC2 instances after business
hours to reduce AWS costs.

## Technologies

-   Python
-   Boto3
-   AWS Lambda
-   Amazon EventBridge (CloudWatch Events)
-   IAM

## Python Script

``` python
import boto3

ec2 = boto3.client("ec2")

response = ec2.describe_instances(
    Filters=[
        {
            "Name": "instance-state-name",
            "Values": ["running"]
        }
    ]
)

for reservation in response["Reservations"]:
    for instance in reservation["Instances"]:
        instance_id = instance["InstanceId"]

        print(f"Stopping {instance_id}")

        ec2.stop_instances(
            InstanceIds=[instance_id]
        )
```

## Enterprise Use Case

-   Scheduled using EventBridge
-   Runs as AWS Lambda
-   Stops Dev and QA instances nightly
-   Saves cloud costs

## Interview Explanation

> I developed Python automation using Boto3 to identify and stop idle
> EC2 instances outside business hours. The solution was executed
> through AWS Lambda on a scheduled EventBridge rule, reducing
> infrastructure costs while ensuring production workloads were
> unaffected.

------------------------------------------------------------------------

# 2. Automated EBS Snapshot Cleanup

## Objective

Delete snapshots older than the retention policy.

## Python Script

``` python
import boto3
from datetime import datetime, timezone

ec2 = boto3.client("ec2")

retention_days = 30

snapshots = ec2.describe_snapshots(
    OwnerIds=["self"]
)["Snapshots"]

for snapshot in snapshots:

    age = datetime.now(timezone.utc) - snapshot["StartTime"]

    if age.days > retention_days:

        print(f"Deleting {snapshot['SnapshotId']}")

        ec2.delete_snapshot(
            SnapshotId=snapshot["SnapshotId"]
        )
```

## Benefits

-   Automated cleanup
-   Reduced storage costs
-   Compliance with retention policies

## Interview Explanation

> I created an automated snapshot lifecycle cleanup process that removed
> outdated EBS snapshots after the configured retention period, reducing
> storage costs and simplifying backup management.

------------------------------------------------------------------------

# 3. Trivy Vulnerability Report Parser

## Objective

Extract Critical vulnerabilities from Trivy JSON reports.

## Python Script

``` python
import json

with open("trivy-report.json") as f:
    report = json.load(f)

critical = []

for result in report.get("Results", []):

    for vuln in result.get("Vulnerabilities", []):

        if vuln["Severity"] == "CRITICAL":

            critical.append({
                "Package": vuln["PkgName"],
                "CVE": vuln["VulnerabilityID"]
            })

print("Critical Vulnerabilities")

for item in critical:
    print(item)
```

## Benefits

-   Faster remediation
-   Reduced manual review
-   Pipeline-friendly reporting

## Interview Explanation

> I built Python automation to parse Trivy JSON reports and generate
> concise summaries of High and Critical vulnerabilities, enabling
> development teams to prioritize remediation quickly.

------------------------------------------------------------------------

# 4. Slack Notification Automation

## Objective

Notify teams when security gates fail.

## Python Script

``` python
import requests

webhook = "https://hooks.slack.com/services/XXXXX"

payload = {
    "text": "Critical vulnerabilities detected in the latest container image."
}

requests.post(webhook, json=payload)
```

## Benefits

-   Real-time alerts
-   Faster incident response
-   Better collaboration

## Interview Explanation

> Whenever a CI/CD security scan failed, the automation sent Slack
> notifications containing build information and vulnerability
> summaries, helping engineers respond immediately.

------------------------------------------------------------------------

# 5. GitHub Pull Request Automation

## Objective

Automatically create Pull Requests after rebuilding patched container
images.

## Python Script

``` python
import requests

token = "GITHUB_TOKEN"

headers = {
    "Authorization": f"Bearer {token}",
    "Accept": "application/vnd.github+json"
}

payload = {
    "title": "Update Base Image",
    "head": "security-update",
    "base": "main",
    "body": "Automated security patch."
}

requests.post(
    "https://api.github.com/repos/org/repo/pulls",
    headers=headers,
    json=payload
)
```

## Benefits

-   Standardized code reviews
-   Merge governance
-   Secure change management

## Interview Explanation

> Instead of pushing changes directly to the main branch, our automation
> generated Pull Requests automatically so that security updates
> followed the organization's review and approval process.

------------------------------------------------------------------------

# 6. Terraform Validation Automation

## Objective

Validate Terraform code before deployment.

## Python Script

``` python
import subprocess

commands = [
    ["terraform", "fmt", "-check"],
    ["terraform", "validate"],
]

for command in commands:

    result = subprocess.run(
        command,
        capture_output=True,
        text=True
    )

    print(result.stdout)

    if result.returncode != 0:
        print(result.stderr)
        exit(1)

print("Terraform validation successful.")
```

## Benefits

-   Detects configuration errors early
-   Prevents failed deployments
-   Improves Infrastructure as Code quality

## Interview Explanation

> I automated Terraform formatting and validation checks as part of the
> CI pipeline, ensuring only syntactically correct and validated
> infrastructure changes progressed toward deployment.

------------------------------------------------------------------------

# 7. GitHub Actions Workflow Trigger

## Objective

Trigger GitHub Actions workflows programmatically.

## Python Script

``` python
import requests

token = "GITHUB_TOKEN"

headers = {
    "Authorization": f"Bearer {token}",
    "Accept": "application/vnd.github+json"
}

payload = {
    "ref": "main"
}

requests.post(
    "https://api.github.com/repos/org/repo/actions/workflows/deploy.yml/dispatches",
    headers=headers,
    json=payload
)
```

## Benefits

-   Automated releases
-   External orchestration
-   Integration with enterprise tools

## Interview Explanation

> I used the GitHub REST API to trigger workflows from external
> automation systems, enabling controlled deployments and integration
> with enterprise release orchestration processes.

------------------------------------------------------------------------

# Summary

These examples demonstrate practical experience with:

-   AWS Automation (Boto3)
-   Infrastructure Automation
-   DevSecOps Pipelines
-   Vulnerability Management
-   GitHub API Integration
-   Terraform Validation
-   Slack Notifications
-   CI/CD Automation

These are the types of automation projects commonly discussed in senior
DevSecOps interviews, as they showcase hands-on scripting skills, cloud
platform knowledge, and secure software delivery practices.
