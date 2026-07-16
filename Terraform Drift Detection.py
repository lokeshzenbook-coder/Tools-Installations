import subprocess
import json
import os
from datetime import datetime

WORKING_DIRECTORY = "./terraform"

REPORT_FILE = "terraform-drift-report.txt"


def run_command(command):

    result = subprocess.run(
        command,
        cwd=WORKING_DIRECTORY,
        capture_output=True,
        text=True
    )

    return result


print("=" * 60)
print("Terraform Drift Detection Started")
print("=" * 60)

# Initialize Terraform
init = run_command(["terraform", "init"])

if init.returncode != 0:
    print(init.stderr)
    exit(1)

# Run Terraform Plan
plan = run_command([
    "terraform",
    "plan",
    "-detailed-exitcode",
    "-no-color"
])

timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

# Exit Codes
# 0 = No Drift
# 2 = Drift Detected
# 1 = Error

if plan.returncode == 0:

    print("No Infrastructure Drift Detected")

elif plan.returncode == 2:

    print("Terraform Drift Detected")

    with open(REPORT_FILE, "w") as report:

        report.write("=" * 60 + "\n")
        report.write("Terraform Drift Report\n")
        report.write("=" * 60 + "\n")
        report.write(f"Generated : {timestamp}\n\n")
        report.write(plan.stdout)

    print(f"Report saved to {REPORT_FILE}")

else:

    print("Terraform Error")
    print(plan.stderr)

    exit(1)

## Slack Notification Integration

import requests

WEBHOOK = "https://hooks.slack.com/services/XXXX"

message = {
    "text": "Terraform Drift Detected.\nReview terraform-drift-report.txt before deployment."
}

requests.post(WEBHOOK, json=message)
