# AWS DevOps / DevSecOps Python Boto3 Automation

Absolutely. For a **DevOps / DevSecOps Engineer**, Python + `boto3` is most valuable when it automates repetitive AWS operational work—not just simple API calls.

Given your AWS/EKS/DevSecOps focus, I would prioritize these scripts:

| # | Automation | Practical value |
|---|---|---|
| 1 | Stop idle EC2 instances | ⭐⭐⭐⭐⭐ |
| 2 | EBS snapshot cleanup | ⭐⭐⭐⭐⭐ |
| 3 | ECR image cleanup | ⭐⭐⭐⭐⭐ |
| 4 | CloudWatch log retention | ⭐⭐⭐⭐⭐ |
| 5 | Find unattached EBS volumes | ⭐⭐⭐⭐⭐ |
| 6 | Find unused Elastic IPs | ⭐⭐⭐⭐ |
| 7 | Detect EC2 security-group risks | ⭐⭐⭐⭐⭐ |
| 8 | Find unencrypted EBS volumes | ⭐⭐⭐⭐⭐ |
| 9 | Terraform drift notification | ⭐⭐⭐⭐⭐ |
| 10 | EKS pod/resource audit | ⭐⭐⭐⭐⭐ |
| 11 | EKS cluster health check | ⭐⭐⭐⭐⭐ |
| 12 | RDS snapshot cleanup | ⭐⭐⭐⭐ |
| 13 | S3 bucket security audit | ⭐⭐⭐⭐⭐ |
| 14 | IAM access-key age audit | ⭐⭐⭐⭐⭐ |
| 15 | AWS cost/resource report | ⭐⭐⭐⭐⭐ |

---

# 1. Stop Idle EC2 Instances

A very common real-world automation.

```python
import boto3

REGION = "ap-south-1"
CPU_THRESHOLD = 5
LOOKBACK_HOURS = 24

ec2 = boto3.client("ec2", region_name=REGION)
cloudwatch = boto3.client("cloudwatch", region_name=REGION)


def get_running_instances():
    response = ec2.describe_instances(
        Filters=[
            {
                "Name": "instance-state-name",
                "Values": ["running"]
            }
        ]
    )

    instances = []

    for reservation in response["Reservations"]:
        for instance in reservation["Instances"]:
            instances.append(instance)

    return instances


def get_cpu(instance_id):

    response = cloudwatch.get_metric_statistics(
        Namespace="AWS/EC2",
        MetricName="CPUUtilization",
        Dimensions=[
            {
                "Name": "InstanceId",
                "Value": instance_id
            }
        ],
        StartTime=__import__("datetime").datetime.utcnow()
        - __import__("datetime").timedelta(hours=LOOKBACK_HOURS),
        EndTime=__import__("datetime").datetime.utcnow(),
        Period=3600,
        Statistics=["Average"]
    )

    datapoints = response["Datapoints"]

    if not datapoints:
        return None

    return sum(
        point["Average"]
        for point in datapoints
    ) / len(datapoints)


for instance in get_running_instances():

    instance_id = instance["InstanceId"]

    cpu = get_cpu(instance_id)

    print(
        f"{instance_id} | CPU: {cpu}"
    )

    if cpu is not None and cpu < CPU_THRESHOLD:

        print(
            f"Stopping idle instance: {instance_id}"
        )

        ec2.stop_instances(
            InstanceIds=[instance_id]
        )
```

### Production improvement

Don't automatically stop every low-CPU instance.

Use a tag:

```text
AutoStop = true
```

Then your automation becomes safer:

```text
EC2
 ↓
CPU < 5%
 ↓
AutoStop=true?
 ↓
YES
 ↓
Stop Instance
```

---

# 2. ECR Image Cleanup

This is especially relevant to your **GitHub Actions → ECR → Kubernetes** workflows.

```python
import boto3

REGION = "ap-south-1"
REPOSITORY = "my-app"
KEEP_IMAGES = 10

ecr = boto3.client(
    "ecr",
    region_name=REGION
)

response = ecr.describe_images(
    repositoryName=REPOSITORY
)

images = response.get("imageDetails", [])

images.sort(
    key=lambda x: x.get("imagePushedAt", 0),
    reverse=True
)

images_to_delete = images[KEEP_IMAGES:]

if not images_to_delete:
    print("Nothing to clean.")
else:

    image_ids = [
        {
            "imageDigest": image["imageDigest"]
        }
        for image in images_to_delete
    ]

    ecr.batch_delete_image(
        repositoryName=REPOSITORY,
        imageIds=image_ids
    )

    print(
        f"Deleted {len(image_ids)} old images."
    )
```

Production flow:

```text
GitHub Actions
      ↓
Docker Build
      ↓
Security Scan
      ↓
ECR
      ↓
Keep latest 10
      ↓
Delete old images
```

---

# 3. Find Unattached EBS Volumes

Very useful for **AWS cost optimization**.

```python
import boto3

REGION = "ap-south-1"

ec2 = boto3.client(
    "ec2",
    region_name=REGION
)

response = ec2.describe_volumes(
    Filters=[
        {
            "Name": "status",
            "Values": ["available"]
        }
    ]
)

for volume in response["Volumes"]:

    print(
        f"Unused EBS Volume: "
        f"{volume['VolumeId']} | "
        f"Size: {volume['Size']} GB | "
        f"Type: {volume['VolumeType']}"
    )
```

I would initially make this **report-only**, rather than automatically deleting volumes.

---

# 4. Find Unused Elastic IPs

```python
import boto3

ec2 = boto3.client(
    "ec2",
    region_name="ap-south-1"
)

response = ec2.describe_addresses()

for address in response["Addresses"]:

    if "InstanceId" not in address:

        print(
            f"Unused Elastic IP: "
            f"{address['PublicIp']}"
        )
```

This is a nice small automation to demonstrate during interviews.

---

# 5. Find Unencrypted EBS Volumes

Useful from a **DevSecOps** perspective.

```python
import boto3

ec2 = boto3.client(
    "ec2",
    region_name="ap-south-1"
)

response = ec2.describe_volumes()

for volume in response["Volumes"]:

    if not volume.get("Encrypted", False):

        print(
            f"UNENCRYPTED: "
            f"{volume['VolumeId']} | "
            f"{volume['Size']} GB"
        )
```

You can extend this to automatically send a notification through SNS.

---

# 6. S3 Security Audit

```python
import boto3

s3 = boto3.client("s3")

response = s3.list_buckets()

for bucket in response["Buckets"]:

    name = bucket["Name"]

    try:

        encryption = s3.get_bucket_encryption(
            Bucket=name
        )

        print(
            f"{name}: Encryption ENABLED"
        )

    except s3.exceptions.ClientError:

        print(
            f"{name}: Encryption NOT CONFIGURED"
        )
```

A production version should also check:

```text
Encryption
Public access
Versioning
Logging
Lifecycle
Bucket policy
TLS enforcement
```

---

# 7. IAM Access Key Age Audit

Excellent DevSecOps automation.

```python
import boto3
from datetime import datetime, timezone

iam = boto3.client("iam")

response = iam.list_users()

for user in response["Users"]:

    username = user["UserName"]

    keys = iam.list_access_keys(
        UserName=username
    )

    for key in keys["AccessKeyMetadata"]:

        created = key["CreateDate"]

        age = (
            datetime.now(timezone.utc)
            - created
        ).days

        print(
            f"{username} | "
            f"{key['AccessKeyId']} | "
            f"{age} days"
        )

        if age > 90:

            print(
                f"WARNING: {username} "
                f"has an access key older than 90 days"
            )
```

---

# 8. EC2 Security Group Audit

Look for unrestricted SSH/RDP:

```python
import boto3

ec2 = boto3.client(
    "ec2",
    region_name="ap-south-1"
)

groups = ec2.describe_security_groups()

for sg in groups["SecurityGroups"]:

    for rule in sg["IpPermissions"]:

        protocol = rule.get("IpProtocol")

        for port in [22, 3389]:

            if (
                rule.get("FromPort") == port
                and rule.get("ToPort") == port
            ):

                for ip_range in rule.get(
                    "IpRanges", []
                ):

                    if ip_range["CidrIp"] == "0.0.0.0/0":

                        print(
                            f"CRITICAL: "
                            f"{sg['GroupId']} "
                            f"allows port {port} "
                            f"from the Internet"
                        )
```

This is the type of script that looks good in a **DevSecOps portfolio** because it combines Python + AWS + security.

---

# 9. CloudWatch Log Retention

The script we discussed earlier:

```text
CloudWatch
     ↓
List Log Groups
     ↓
Check Retention
     ↓
Set 30/90/365 days
```

This is better implemented as a scheduled Lambda/EventBridge automation.

---

# 10. EKS Cluster Audit

For your Kubernetes focus, combine `boto3` with `kubectl`.

```python
import boto3
import subprocess

REGION = "ap-south-1"

eks = boto3.client(
    "eks",
    region_name=REGION
)

clusters = eks.list_clusters()["clusters"]

for cluster in clusters:

    response = eks.describe_cluster(
        name=cluster
    )

    status = response["cluster"]["status"]

    version = response["cluster"]["version"]

    print(
        f"{cluster} | "
        f"Status: {status} | "
        f"Kubernetes: {version}"
    )
```

Then extend it to check:

```text
EKS cluster status
Kubernetes version
Node groups
Node health
Pod failures
CPU/memory
Pending pods
ImagePullBackOff
CrashLoopBackOff
```

---

# ⭐ The best portfolio project

Instead of having 15 unrelated Python scripts, I'd create one repository:

```text
aws-devops-automation/
│
├── ec2/
│   ├── stop_idle_instances.py
│   └── security_group_audit.py
│
├── ebs/
│   ├── snapshot_cleanup.py
│   └── unattached_volume_audit.py
│
├── ecr/
│   └── image_cleanup.py
│
├── cloudwatch/
│   └── log_retention.py
│
├── s3/
│   └── security_audit.py
│
├── iam/
│   └── access_key_audit.py
│
├── eks/
│   ├── cluster_health.py
│   └── pod_audit.py
│
├── cost/
│   └── resource_report.py
│
├── requirements.txt
├── README.md
└── .github/
    └── workflows/
        └── automation.yml
```

Then automate execution:

```text
                 GitHub
                    │
                    ▼
             GitHub Actions
                    │
                    ▼
              Python Boto3
                    │
       ┌────────────┼─────────────┐
       ▼            ▼             ▼
      EC2          ECR           EKS
       │            │             │
       ▼            ▼             ▼
     Cost        Cleanup        Health
    Security     Images         Audit
       │            │             │
       └────────────┼─────────────┘
                    ▼
                   SNS
                    │
                    ▼
               Notification
```

For **your career profile**, the strongest five to actually build and demonstrate are:

**1. EKS Health & Pod Audit**  
**2. ECR Image Cleanup**  
**3. Terraform Drift Detection**  
**4. EC2/EBS Cost Optimization**  
**5. AWS Security Misconfiguration Audit**

Those five show much more senior-level capability than a collection of basic `boto3` scripts.
