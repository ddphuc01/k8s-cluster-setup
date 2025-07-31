# Tempo Practical Guide - Sử dụng Explore và Dashboard

## 🎯 **Hướng dẫn thực hành từng bước**

### **Bước 1: Truy cập Tempo Explore**

1. **Mở Grafana**: http://grafana.local
2. **Đăng nhập**: Username `admin`, Password từ secret
3. **Vào Explore**: Click biểu tượng compass (🔍) ở sidebar
4. **Chọn Tempo**: Từ dropdown datasource, chọn **Tempo**

---

## 🔍 **Thực hành với Tempo Explore**

### **1. Basic Queries - Thử ngay**

#### **Query 1: Xem tất cả traces**
```
{}
```
- **Mục đích**: Xem tất cả traces trong hệ thống
- **Kết quả mong đợi**: Danh sách traces (có thể trống nếu chưa có traces)

#### **Query 2: Filter theo service**
```
{service.name="prometheus"}
```
- **Mục đích**: Xem traces từ service Prometheus
- **Kết quả mong đợi**: Traces từ Prometheus service

#### **Query 3: Filter theo duration**
```
{duration > 1s}
```
- **Mục đích**: Xem traces có thời gian > 1 giây
- **Kết quả mong đợi**: Traces chậm

### **2. Advanced Queries - Khi có traces**

#### **Query 4: Multiple filters**
```
{service.name="api-gateway", operation="GET", duration > 500ms}
```
- **Mục đích**: Tìm traces từ API Gateway, GET requests, > 500ms

#### **Query 5: Error traces**
```
{status="error"}
```
- **Mục đích**: Xem tất cả error traces

#### **Query 6: HTTP specific**
```
{http.method="POST", http.status_code="500"}
```
- **Mục đích**: Tìm POST requests với status 500

---

## 📊 **Tạo Dashboard từ Explore**

### **Bước 1: Tạo query trong Explore**

1. **Nhập query**: `{}` (hoặc query khác)
2. **Chọn time range**: `Last 1 hour`
3. **Click Run Query**: Để test query
4. **Xem kết quả**: Nếu có traces, sẽ hiển thị danh sách

### **Bước 2: Thêm vào Dashboard**

1. **Click Add to dashboard**: Biểu tượng + ở góc trên bên phải
2. **Chọn option**:
   - **Add to existing dashboard**: Thêm vào dashboard có sẵn
   - **Create new dashboard**: Tạo dashboard mới
3. **Đặt tên panel**: Ví dụ "All Traces"
4. **Click Add to dashboard**

### **Bước 3: Tùy chỉnh Panel**

1. **Chọn visualization**: 
   - **Table**: Danh sách traces
   - **Node Graph**: Service map
   - **Time series**: Metrics từ traces
2. **Điều chỉnh settings**: Title, description, size
3. **Save dashboard**

---

## 🎨 **Tạo Dashboard từ Scratch**

### **Bước 1: Tạo Dashboard mới**

1. **Vào +** → **Dashboard**
2. **Click Add new panel**
3. **Chọn Tempo datasource**

### **Bước 2: Thêm Service Map Panel**

1. **Query**: `traces_service_graph_request_total`
2. **Visualization**: **Node Graph**
3. **Title**: "Service Dependencies"
4. **Save panel**

### **Bước 3: Thêm Latency Panel**

1. **Datasource**: **Prometheus**
2. **Query**: 
```promql
histogram_quantile(0.95, sum(rate(traces_spanmetrics_duration_seconds_bucket[5m])) by (le, service_name))
```
3. **Visualization**: **Time series**
4. **Title**: "95th Percentile Latency"
5. **Save panel**

### **Bước 4: Thêm Error Rate Panel**

1. **Datasource**: **Prometheus**
2. **Query**:
```promql
sum(rate(traces_spanmetrics_calls_total{status_code="error"}[5m])) by (service_name) / sum(rate(traces_spanmetrics_calls_total[5m])) by (service_name) * 100
```
3. **Visualization**: **Stat**
4. **Title**: "Error Rate (%)"
5. **Save panel**

---

## 🚀 **Dashboard Templates**

### **Template 1: Tempo Overview Dashboard**

#### **Panels cần tạo:**

1. **Trace Rate (Stat Panel)**
   - **Datasource**: Prometheus
   - **Query**: `sum(rate(traces_spanmetrics_calls_total[5m])) by (service_name)`
   - **Title**: "Trace Rate (calls/sec)"

2. **Service Latency (Time Series)**
   - **Datasource**: Prometheus
   - **Query**: `histogram_quantile(0.95, sum(rate(traces_spanmetrics_duration_seconds_bucket[5m])) by (le, service_name))`
   - **Title**: "95th Percentile Latency"

3. **Error Rate (Stat Panel)**
   - **Datasource**: Prometheus
   - **Query**: `sum(rate(traces_spanmetrics_calls_total{status_code="error"}[5m])) by (service_name) / sum(rate(traces_spanmetrics_calls_total[5m])) by (service_name) * 100`
   - **Title**: "Error Rate (%)"

4. **Service Map (Node Graph)**
   - **Datasource**: Tempo
   - **Query**: `traces_service_graph_request_total`
   - **Title**: "Service Dependencies"

### **Template 2: Service-specific Dashboard**

#### **Panels cần tạo:**

1. **Service Latency (Time Series)**
   - **Query**: `histogram_quantile(0.95, sum(rate(traces_spanmetrics_duration_seconds_bucket[5m])) by (le, service_name))`
   - **Filter**: `{service_name="$service"}`

2. **Service Errors (Time Series)**
   - **Query**: `sum(rate(traces_spanmetrics_calls_total{status_code="error"}[5m])) by (service_name)`
   - **Filter**: `{service_name="$service"}`

3. **Service Traces (Table)**
   - **Datasource**: Tempo
   - **Query**: `{service.name="$service"}`

---

## 🔧 **Variables cho Dashboard**

### **Tạo Service Variable**

1. **Vào Dashboard Settings** → **Variables**
2. **Add variable**:
   - **Name**: `service`
   - **Type**: Query
   - **Datasource**: Prometheus
   - **Query**: `label_values(traces_spanmetrics_calls_total, service_name)`
   - **Include All option**: Yes

### **Sử dụng Variable trong Queries**

1. **Prometheus queries**:
```promql
histogram_quantile(0.95, sum(rate(traces_spanmetrics_duration_seconds_bucket[5m])) by (le, service_name)){service_name="$service"}
```

2. **Tempo queries**:
```
{service.name="$service"}
```

---

## 📈 **Useful Queries Reference**

### **Performance Queries**
```promql
# 95th percentile latency
histogram_quantile(0.95, sum(rate(traces_spanmetrics_duration_seconds_bucket[5m])) by (le, service_name))

# 99th percentile latency
histogram_quantile(0.99, sum(rate(traces_spanmetrics_duration_seconds_bucket[5m])) by (le, service_name))

# Average latency
sum(rate(traces_spanmetrics_duration_seconds_sum[5m])) by (service_name) / sum(rate(traces_spanmetrics_duration_seconds_count[5m])) by (service_name)
```

### **Error Queries**
```promql
# Error rate
sum(rate(traces_spanmetrics_calls_total{status_code="error"}[5m])) by (service_name) / sum(rate(traces_spanmetrics_calls_total[5m])) by (service_name) * 100

# Error count
sum(rate(traces_spanmetrics_calls_total{status_code="error"}[5m])) by (service_name)
```

### **Throughput Queries**
```promql
# Calls per second
sum(rate(traces_spanmetrics_calls_total[5m])) by (service_name)

# Total calls
sum(traces_spanmetrics_calls_total) by (service_name)
```

### **Tempo Queries**
```
# All traces
{}

# Service traces
{service.name="your-service"}

# Error traces
{status="error"}

# Slow traces
{duration > 1s}

# HTTP errors
{http.status_code="500"}
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
- Tạo service variable để filter
- Sử dụng variables trong queries
- Include "All" option cho variables

---

## 🛠️ **Troubleshooting**

### **1. No Traces Found**
- Kiểm tra xem applications đã được instrument chưa
- Kiểm tra Tempo logs: `kubectl logs -n monitoring -l app.kubernetes.io/name=tempo`
- Test OTLP endpoint: `curl http://localhost:3200/ready`

### **2. Dashboard Not Loading**
- Kiểm tra Grafana logs: `kubectl logs -n monitoring -l app=grafana`
- Kiểm tra datasource: `kubectl get configmap grafana-datasources -n monitoring`

### **3. Query Errors**
- Kiểm tra syntax của queries
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
- **Custom Dashboards**: Tạo theo hướng dẫn trên

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

**Status**: ✅ **READY TO PRACTICE**  
**Last Updated**: 31/07/2025  
**Next**: Start exploring và tạo dashboards theo hướng dẫn 