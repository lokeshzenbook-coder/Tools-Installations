# Python Automation: Istio Traffic Analysis

## Objective

This automation collects traffic metrics from **Prometheus** for an
**Istio Service Mesh** and helps identify:

-   High traffic services
-   High error rate services
-   Services with high latency
-   Generates a CSV report
-   Sends Slack alerts (optional)

------------------------------------------------------------------------

# Architecture

``` text
+----------------------+
|  Python Automation   |
+----------+-----------+
           |
           ▼
+----------------------+
| Prometheus API       |
+----------+-----------+
           |
           ▼
+----------------------+
| Istio Metrics        |
| (Envoy Sidecars)     |
+----------+-----------+
           |
           ▼
+----------------------+
| Analyze              |
| - Traffic            |
| - Errors             |
| - Latency            |
+----------+-----------+
           |
           ▼
+----------------------+
| Report / Slack Alert |
+----------------------+
```

# Required Libraries

``` bash
pip install requests pandas
```

# Python Script

``` python
import requests
import pandas as pd

PROMETHEUS_URL = "http://prometheus.monitoring.svc:9090"

queries = {
    "Traffic (RPS)": """
        sum(rate(istio_requests_total[5m]))
        by (destination_workload)
    """,
    "Error Rate": """
        sum(rate(istio_requests_total{
            response_code=~"5.*"
        }[5m]))
        by (destination_workload)
    """,
    "Latency (P95)": """
        histogram_quantile(
            0.95,
            sum(
                rate(
                    istio_request_duration_milliseconds_bucket[5m]
                )
            ) by (le,destination_workload)
        )
    """
}

report = []

for metric, query in queries.items():
    response = requests.get(
        f"{PROMETHEUS_URL}/api/v1/query",
        params={"query": query}
    )

    data = response.json()

    if data["status"] != "success":
        continue

    for result in data["data"]["result"]:
        workload = result["metric"].get(
            "destination_workload",
            "unknown"
        )

        value = float(result["value"][1])

        report.append({
            "Service": workload,
            "Metric": metric,
            "Value": round(value, 2)
        })

df = pd.DataFrame(report)

print(df)

df.to_csv("istio-traffic-report.csv", index=False)

print("Traffic report generated successfully.")
```

# Sample Output

``` text
Service          Metric              Value
user-api         Traffic (RPS)       142.5
order-api        Traffic (RPS)        65.2
payment-api      Traffic (RPS)        28.7
payment-api      Error Rate            3.2
inventory-api    Latency (P95)       845
```

# Detect High Error Rate

``` python
errors = df[
    (df["Metric"] == "Error Rate")
    &
    (df["Value"] > 1)
]

print(errors)
```

# Detect High Latency

``` python
latency = df[
    (df["Metric"] == "Latency (P95)")
    &
    (df["Value"] > 500)
]

print(latency)
```

# Slack Notification

``` python
import requests

webhook = "YOUR_SLACK_WEBHOOK"

message = {
    "text": "Istio Traffic Report Generated. Check services with high latency and 5xx errors."
}

requests.post(webhook, json=message)
```

# Interview Explanation

> I developed Python automation that queried Prometheus metrics from an
> Istio service mesh to analyze request rates, 5xx error rates, and P95
> latency for each workload. The script generated CSV reports,
> highlighted services exceeding thresholds, and optionally sent Slack
> notifications. This improved observability and accelerated incident
> detection.

# Future Enhancements

-   Grafana integration
-   ServiceNow incident creation
-   Argo Workflows remediation
-   mTLS failure detection
-   East-west traffic analysis
-   Scheduled execution with CronJobs
