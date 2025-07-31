# Tempo Explore & Dashboard Guide

## 🎯 **Hướng dẫn sử dụng Tempo Explore**

### **1. Truy cập Tempo Explore**

#### **Cách 1: Từ Grafana Home**
1. Truy cập **http://grafana.local**
2. Click **Explore** (biểu tượng compass) ở sidebar bên trái
3. Chọn **Tempo** từ dropdown datasource

#### **Cách 2: Từ Data Sources**
1. Vào **Configuration** → **Data Sources**
2. Click vào **Tempo** datasource
3. Click **Explore** button

---

## 🔍 **Sử dụng Tempo Explore**

### **1. Basic Trace Queries**

#### **Xem tất cả traces:**
```
{}
```

#### **Filter theo service:**
```
{service.name="your-service-name"}
```

#### **Filter theo operation:**
```
{operation="GET /api/users"}
```

#### **Filter theo duration:**
```
{duration > 1s}
```

#### **Filter theo error:**
```
{status="error"}
```

### **2. Advanced Queries**

#### **Multiple filters:**
```
{service.name="api-gateway", operation="POST", duration > 500ms}
```

#### **Filter theo tags:**
```
{http.method="GET", http.status_code="200"}
```

#### **Filter theo time range:**
```
{service.name="payment-service"} | duration > 2s
```

### **3. TraceQL Queries (Advanced)**

#### **Duration-based filtering:**
```
{service.name="order-service"} | duration > 1s and duration < 5s
```

#### **Error traces:**
```
{service.name="user-service"} | status = "error"
```

#### **Specific operations:**
```
{service.name="inventory-service"} | operation = "GET /products"
```

---

## 📊 **Tạo Dashboard từ Explore**

### **1. Từ Explore Panel**

#### **Bước 1: Tạo query trong Explore**
1. Vào **Explore** → Chọn **Tempo**
2. Nhập query: `{service.name="your-service"}`
3. Chọn time range: `Last 1 hour`
4. Click **Run Query**

#### **Bước 2: Thêm vào Dashboard**
1. Click **Add to dashboard** button (biểu tượng +)
2. Chọn **Add to existing dashboard** hoặc **Create new dashboard**
3. Đặt tên panel: "Service Traces"
4. Click **Add to dashboard**

### **2. Tạo Dashboard từ Scratch**

#### **Bước 1: Tạo Dashboard mới**
1. Vào **+** → **Dashboard**
2. Click **Add new panel**

#### **Bước 2: Thêm Tempo Panel**
1. Chọn **Tempo** datasource
2. Nhập query: `{}`
3. Chọn visualization: **Node Graph** (cho Service Map)
4. Đặt title: "Service Dependencies"

---

## 🎨 **Dashboard Panel Types**

### **1. Node Graph (Service Map)**
```json
{
  "title": "Service Dependencies",
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

### **2. Time Series (Latency)**
```json
{
  "title": "Service Latency",
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

### **3. Stat Panel (Error Rate)**
```json
{
  "title": "Error Rate",
  "type": "stat",
  "datasource": "Prometheus",
  "targets": [
    {
      "expr": "sum(rate(traces_spanmetrics_calls_total{status_code=\"error\"}[5m])) by (service_name) / sum(rate(traces_spanmetrics_calls_total[5m])) by (service_name) * 100",
      "legendFormat": "{{service_name}}"
    }
  ]
}
```

---

## 🚀 **Tạo Dashboard Templates**

### **1. Tempo Overview Dashboard**

#### **Panels cần có:**
1. **Trace Rate** - Số lượng traces/giây
2. **95th Percentile Latency** - Latency 95%
3. **Error Rate** - Tỷ lệ lỗi
4. **Service Map** - Node Graph
5. **Recent Traces** - Danh sách traces gần đây

### **2. Service-specific Dashboard**

#### **Panels cần có:**
1. **Service Latency** - Latency theo thời gian
2. **Service Errors** - Errors theo thời gian
3. **Service Dependencies** - Services gọi đến
4. **Trace Details** - Chi tiết traces

---

## 🔧 **Cách thêm Panel vào Dashboard**

### **1. Từ Explore**
1. Vào **Explore** → **Tempo**
2. Tạo query và test
3. Click **Add to dashboard**
4. Chọn dashboard target
5. Đặt tên panel

### **2. Từ Dashboard Editor**
1. Mở dashboard
2. Click **Add panel**
3. Chọn **Tempo** datasource
4. Nhập query
5. Chọn visualization type
6. Save panel

### **3. Import Dashboard**
1. Vào **+** → **Import**
2. Nhập Dashboard ID hoặc JSON
3. Chọn datasources
4. Import

---

## 📈 **Useful Queries**

### **1. Performance Queries**
```promql
# 95th percentile latency
histogram_quantile(0.95, sum(rate(traces_spanmetrics_duration_seconds_bucket[5m])) by (le, service_name))

# 99th percentile latency
histogram_quantile(0.99, sum(rate(traces_spanmetrics_duration_seconds_bucket[5m])) by (le, service_name))

# Average latency
sum(rate(traces_spanmetrics_duration_seconds_sum[5m])) by (service_name) / sum(rate(traces_spanmetrics_duration_seconds_count[5m])) by (service_name)
```

### **2. Error Queries**
```promql
# Error rate
sum(rate(traces_spanmetrics_calls_total{status_code="error"}[5m])) by (service_name) / sum(rate(traces_spanmetrics_calls_total[5m])) by (service_name) * 100

# Error count
sum(rate(traces_spanmetrics_calls_total{status_code="error"}[5m])) by (service_name)
```

### **3. Throughput Queries**
```promql
# Calls per second
sum(rate(traces_spanmetrics_calls_total[5m])) by (service_name)

# Total calls
sum(traces_spanmetrics_calls_total) by (service_name)
```

---

## 🎯 **Best Practices**

### **1. Dashboard Organization**
- **Overview Dashboard**: Tổng quan toàn bộ system
- **Service Dashboards**: Chi tiết từng service
- **Alerting Dashboard**: Metrics cho alerting

### **2. Panel Naming**
- Sử dụng tên rõ ràng: "API Gateway - 95th Percentile Latency"
- Thêm units: "Response Time (ms)", "Error Rate (%)"
- Group related panels

### **3. Time Ranges**
- **Overview**: Last 1 hour, 5m refresh
- **Service Details**: Last 30 minutes, 1m refresh
- **Debugging**: Last 15 minutes, 30s refresh

### **4. Variables**
- Tạo service variable: `label_values(traces_spanmetrics_calls_total, service_name)`
- Tạo operation variable: `label_values(traces_spanmetrics_calls_total, operation)`
- Sử dụng variables trong queries: `{service_name="$service"}`

---

## 🛠️ **Troubleshooting**

### **1. No Traces Found**
```bash
# Check if applications are instrumented
kubectl get pods -A | grep -E "(otel|jaeger|tempo)"

# Check Tempo logs
kubectl logs -n monitoring -l app.kubernetes.io/name=tempo --tail=10

# Test OTLP endpoint
kubectl port-forward -n monitoring svc/tempo 4317:4317 &
curl -X POST http://localhost:4317/v1/traces
```

### **2. Dashboard Not Loading**
```bash
# Check Grafana logs
kubectl logs -n monitoring -l app=grafana -c grafana --tail=10

# Check datasource
kubectl get configmap grafana-datasources -n monitoring -o yaml
```

### **3. Query Errors**
- Kiểm tra syntax của TraceQL queries
- Đảm bảo service names đúng
- Kiểm tra time range

---

## 📞 **Next Steps**

### **1. Instrument Applications**
```yaml
# Add to your deployment
env:
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: "http://tempo:4317"
- name: OTEL_SERVICE_NAME
  value: "your-service"
- name: OTEL_TRACES_SAMPLER
  value: "always_on"
```

### **2. Import Pre-built Dashboards**
- **Tempo Service Map**: ID 12019
- **Custom Dashboards**: Tạo theo nhu cầu

### **3. Setup Alerts**
```yaml
groups:
  - name: trace-alerts
    rules:
      - alert: HighLatency
        expr: histogram_quantile(0.95, sum(rate(traces_spanmetrics_duration_seconds_bucket[5m])) by (le, service_name)) > 1
        for: 2m
```

---

**Status**: ✅ **READY TO USE**  
**Last Updated**: 31/07/2025  
**Next**: Start exploring traces và tạo dashboards 