# Tempo Deployment Guide

## 🎯 **Tempo Overview**

**Tempo** là distributed tracing backend được thiết kế để tích hợp hoàn hảo với Grafana, Prometheus, và Loki.

### **Features:**
- ✅ **Distributed Tracing**: End-to-end request tracing
- ✅ **Grafana Integration**: Native integration với Grafana
- ✅ **Correlation**: Traces ↔ Logs ↔ Metrics
- ✅ **High Performance**: Object storage backend
- ✅ **Scalable**: Horizontal scaling support

---

## 🏗️ **Architecture**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │    │   Tempo Agent   │    │     Tempo       │
│   (Instrumented)│───▶│   (OTEL/OTLP)   │───▶│  (Backend)      │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Grafana       │    │   Object Storage│
                       │  (Tempo UI)     │    │   (S3/MinIO)    │
                       └─────────────────┘    └─────────────────┘
```

---

## 🚀 **Deployment Options**

### **Option 1: Helm Chart (Recommended)**

```bash
# Add Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Tempo
helm install tempo grafana/tempo \
  --namespace monitoring \
  --create-namespace \
  -f k8s-cluster-setup/manifests/monitoring/tempo-values.yaml
```

### **Option 2: Manual YAML**

```bash
# Apply Tempo manifests
kubectl apply -f k8s-cluster-setup/manifests/monitoring/tempo-manual.yaml
```

---

## 🔧 **Configuration**

### **Tempo Values (tempo-values.yaml)**
```yaml
tempo:
  auth_enabled: false
  
  storage:
    trace:
      backend: local  # or s3, gcs, azure
      local:
        path: /var/tempo/traces
      wal:
        path: /var/tempo/wal

  retention: 24h  # Trace retention period

  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi

  persistence:
    enabled: true
    size: 5Gi
    storageClassName: local-path
```

### **Grafana Datasource Configuration**
```yaml
- name: Tempo
  type: tempo
  url: http://tempo:3200
  access: proxy
  jsonData:
    tracesToLogs:
      datasourceUid: loki
      tags: ['job', 'instance', 'pod', 'namespace']
    tracesToMetrics:
      datasourceUid: prometheus
      tags: [{ key: 'service.name', value: 'service' }]
```

---

## 📊 **Integration với Stack hiện tại**

### **Observability Stack hoàn chỉnh:**
```
┌─────────────────────────────────────────────────────────────┐
│                    Grafana                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Metrics    │  │    Logs     │  │   Traces    │        │
│  │(Prometheus) │  │   (Loki)    │  │   (Tempo)   │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
         │                │                │
         ▼                ▼                ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ Prometheus  │  │    Loki     │  │    Tempo    │
│ (Metrics)   │  │   (Logs)    │  │  (Traces)   │
└─────────────┘  └─────────────┘  └─────────────┘
```

### **Correlation Features:**
- **Traces → Logs**: Từ trace span đến log entries
- **Traces → Metrics**: Từ trace đến performance metrics
- **Service Map**: Visual service dependencies
- **Node Graph**: Interactive service topology

---

## 🎨 **Application Instrumentation**

### **1. OpenTelemetry (OTEL) - Recommended**

```python
# Python Example
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Setup tracer
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

# Configure exporter
otlp_exporter = OTLPSpanExporter(endpoint="http://tempo:4317")
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

# Create spans
with tracer.start_as_current_span("api_request") as span:
    span.set_attribute("http.method", "GET")
    span.set_attribute("http.url", "/api/users")
    # Your business logic here
```

### **2. Jaeger Client**

```python
# Python Jaeger Example
from jaeger_client import Config

config = Config(
    config={
        'sampler': {'type': 'const', 'param': 1},
        'local_agent': {'reporting_host': 'tempo', 'reporting_port': 6831},
        'logging': True,
    },
    service_name='my-service'
)
tracer = config.initialize_tracer()
```

### **3. Kubernetes Deployment với OTEL**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: my-app
        image: my-app:latest
        env:
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: "http://tempo:4317"
        - name: OTEL_SERVICE_NAME
          value: "my-service"
        - name: OTEL_TRACES_SAMPLER
          value: "always_on"
```

---

## 📈 **Dashboard Examples**

### **1. Tempo Service Map Dashboard**
```json
{
  "title": "Tempo Service Map",
  "type": "nodeGraph",
  "datasource": "Tempo",
  "targets": [
    {
      "expr": "traces_service_graph_request_total",
      "legendFormat": "{{service_name}}"
    }
  ]
}
```

### **2. Trace Latency Dashboard**
```json
{
  "title": "Trace Latency",
  "type": "timeseries",
  "datasource": "Prometheus",
  "targets": [
    {
      "expr": "histogram_quantile(0.95, sum(rate(traces_spanmetrics_duration_seconds_bucket[5m])) by (le, service_name))",
      "legendFormat": "{{service_name}}"
    }
  ]
}
```

---

## 🔍 **Usage Examples**

### **1. View Traces trong Grafana**
1. Vào Grafana → Explore
2. Chọn Tempo datasource
3. Search traces by:
   - **Trace ID**: Direct trace lookup
   - **Service Name**: Filter by service
   - **Tags**: Filter by attributes
   - **Time Range**: Recent traces

### **2. Correlate Traces với Logs**
1. Open a trace trong Tempo
2. Click on any span
3. Click "View Logs" → Opens Loki với trace context
4. See logs for that specific request

### **3. Service Map**
1. Vào Grafana → Dashboards
2. Import Tempo Service Map dashboard
3. View service dependencies và traffic flow

---

## 🚨 **Alerting với Traces**

### **Trace-based Alerts**
```yaml
groups:
  - name: trace-alerts
    rules:
      - alert: HighTraceLatency
        expr: histogram_quantile(0.95, sum(rate(traces_spanmetrics_duration_seconds_bucket[5m])) by (le, service_name)) > 1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High trace latency detected"
          description: "Service {{ $labels.service_name }} has high latency"
```

---

## 🛠️ **Troubleshooting**

### **Common Issues**

#### **1. Tempo không nhận traces**
```bash
# Check Tempo status
kubectl get pods -n monitoring | grep tempo

# Check Tempo logs
kubectl logs -n monitoring -l app.kubernetes.io/name=tempo

# Test OTLP endpoint
kubectl port-forward -n monitoring svc/tempo 4317:4317
# Then test with OTEL collector
```

#### **2. Grafana không thấy Tempo datasource**
```bash
# Check datasource config
kubectl get configmap grafana-datasources -n monitoring -o yaml

# Restart Grafana
kubectl rollout restart deployment prometheus-grafana -n monitoring
```

#### **3. Traces không correlate với logs**
```bash
# Check Tempo config
kubectl get configmap tempo -n monitoring -o yaml

# Verify Loki integration
kubectl logs -n monitoring -l app.kubernetes.io/name=tempo | grep -i "loki"
```

---

## 📊 **Performance Considerations**

### **Resource Requirements**
- **Small Cluster**: 128Mi RAM, 100m CPU
- **Medium Cluster**: 256Mi RAM, 200m CPU
- **Large Cluster**: 512Mi RAM, 500m CPU

### **Storage Requirements**
- **Retention**: 24h = ~1GB per 1000 traces/second
- **WAL**: Additional 20% for write-ahead log
- **Total**: ~1.2GB per 1000 traces/second

### **Scaling**
- **Horizontal**: Multiple Tempo instances
- **Vertical**: Increase CPU/Memory
- **Storage**: Use S3/GCS for large scale

---

## 🎯 **Next Steps**

### **Immediate Actions**
1. **Deploy Tempo** using Helm
2. **Update Grafana datasources** với Tempo
3. **Instrument applications** với OTEL
4. **Create trace dashboards**

### **Advanced Setup**
1. **Configure S3 storage** for production
2. **Setup trace sampling** strategies
3. **Create custom trace dashboards**
4. **Setup trace-based alerting**

---

## 📞 **Support**

### **Documentation**
- **Tempo Docs**: https://grafana.com/docs/tempo/
- **OTEL Docs**: https://opentelemetry.io/docs/
- **Grafana Tempo**: https://grafana.com/oss/tempo/

### **Community**
- **GitHub**: https://github.com/grafana/tempo
- **Slack**: Grafana Community Slack
- **Discussions**: GitHub Discussions

---

**Status**: 🚀 **READY FOR DEPLOYMENT**  
**Last Updated**: 31/07/2025  
**Version**: 1.0 