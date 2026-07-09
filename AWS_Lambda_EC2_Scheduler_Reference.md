# AWS Lambda Automation: Start & Stop Amazon EC2 Instances on a Schedule

## Overview

This repository demonstrates how to automatically start and stop Amazon
EC2 instances at specified times (for example, every morning and
evening) using:

-   AWS Lambda (Python/Boto3)
-   Amazon EventBridge Scheduler (Cron)
-   IAM Role
-   CloudWatch Logs

## Repository Structure

``` text
ec2-scheduler/
├── lambda_function.py
├── README.md
└── iam-policy.json
```

## Lambda Function (Python/Boto3)

``` python
import boto3
import os

ec2 = boto3.client("ec2")

INSTANCE_IDS = os.environ["INSTANCE_IDS"].split(",")
ACTION = os.environ["ACTION"]

def lambda_handler(event, context):
    if ACTION.lower() == "start":
        ec2.start_instances(InstanceIds=INSTANCE_IDS)
        return {"message": "Instances started"}
    elif ACTION.lower() == "stop":
        ec2.stop_instances(InstanceIds=INSTANCE_IDS)
        return {"message": "Instances stopped"}
    else:
        raise ValueError("ACTION must be start or stop")
```

## EventBridge Cron Schedules

### Start EC2 every morning at 8:00 AM IST

``` text
cron(30 2 * * ? *)
```

### Stop EC2 every evening at 8:00 PM IST

``` text
cron(30 14 * * ? *)
```

> EventBridge cron expressions use UTC.\
> 08:00 IST = 02:30 UTC\
> 20:00 IST = 14:30 UTC

## Lambda Environment Variables

  Variable       Example
  -------------- -----------------------------------------
  INSTANCE_IDS   i-0123456789abcdef0,i-0abcdef1234567890
  ACTION         start or stop

## Required IAM Permissions

``` json
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Effect":"Allow",
      "Action":[
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:DescribeInstances"
      ],
      "Resource":"*"
    }
  ]
}
```

## Deployment Steps

1.  Create a Lambda function using Python 3.x.
2.  Attach the IAM policy above to the Lambda execution role.
3.  Configure the environment variables.
4.  Create two EventBridge Scheduler rules:
    -   Morning Start
    -   Evening Stop
5.  Test the Lambda function and verify execution in CloudWatch Logs.

## Repository Reference

Replace the placeholder below with your repository URL:

``` text
https://github.com/<your-username>/<your-repository>
```

Example:

``` text
https://github.com/johndoe/aws-lambda-ec2-scheduler
```
