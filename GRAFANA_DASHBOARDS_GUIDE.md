# Grafana Dashboards Guide

## 🎯 **Dashboard Recommendations cho Grafana**

### ✅ **Đã khắc phục vấn đề Drilldown**

**Vấn đề**: Grafana drilldown báo lỗi `limits_config: volume_enabled: true`

**Giải pháp**: Đã cập nhật cấu hình Loki với `volume_enabled: true` và restart Loki

### 📊 **Dashboard đã tạo:**

#### 1. **Kubernetes Logs Dashboard** 
- **UID**: `kubernetes-logs`
- **Mục đích**: Monitoring logs từ tất cả pods trong cluster
- **Features**:
  - Logs phân bổ theo namespace (pie chart)
  - Error logs real-time
  - Variables: namespace, application
  - Drilldown support ✅

#### 2. **Loki Performance Dashboard**
- **UID**: `loki-performance` 
- **Mục đích**: Monitoring performance của Loki
- **Features**:
  - Log ingestion rate
  - Memory usage
  - Request duration
  - Total log entries

### 🚀 **Cách Import Dashboard từ Grafana.com**

#### **Recommended Dashboards:**

1. **Kubernetes Cluster Monitoring**
   - **ID**: 315
   - **URL**: https://grafana.com/grafana/dashboards/315
   - **Mô tả**: Comprehensive Kubernetes monitoring

2. **Kubernetes Cluster (Prometheus)**
   - **ID**: 7249
   - **URL**: https://grafana.com/grafana/dashboards/7249
   - **Mô tả**: Advanced Kubernetes metrics

3. **Loki Dashboard**
   - **ID**: 12019
   - **URL**: https://grafana.com/grafana/dashboards/12019
   - **Mô tả**: Loki performance monitoring

4. **Node Exporter Full**
   - **ID**: 1860
   - **URL**: https://grafana.com/grafana/dashboards/1860
   - **Mô tả**: Node metrics monitoring

### 📋 **Cách Import Dashboard:**

#### **Method 1: Via Grafana UI**
1. Truy cập Grafana: http://grafana.local
2. Vào **+** → **Import**
3. Nhập Dashboard ID (ví dụ: 315)
4. Chọn datasource: **Prometheus**
5. Click **Import**

#### **Method 2: Via ConfigMap (Recommended)**
```bash
# Tạo ConfigMap cho dashboard
kubectl create configmap grafana-dashboard-315 \
  --from-file=315.json \
  -n monitoring \
  --dry-run=client -o yaml | \
  sed 's/grafana-dashboard-315/grafana-dashboard-315/' | \
  sed '/grafana_dashboard: "1"/a\  grafana_dashboard: "1"' | \
  kubectl apply -f -
```

### 🔧 **Cấu hình Loki cho Drilldown**

#### **File**: `loki-config-with-volume.yaml`
```yaml
limits_config:
  # ... other configs ...
  volume_enabled: true  # ← Quan trọng cho drilldown!
```

#### **Apply cấu hình:**
```bash
kubectl apply -f k8s-cluster-setup/manifests/monitoring/loki-config-with-volume.yaml
kubectl rollout restart deployment loki -n monitoring
```

### 📈 **Dashboard Features:**

#### **Kubernetes Logs Dashboard:**
- **Variables**: namespace, application
- **Panels**:
  - Logs by Namespace (Pie Chart)
  - Error Logs (Logs Panel)
  - Warning Count (Stat)
  - Fatal Count (Stat)
  - Total Logs (Stat)

#### **Loki Performance Dashboard:**
- **Panels**:
  - Total Log Entries
  - Log Ingestion Rate
  - Memory Usage
  - Request Duration

### 🎨 **Custom Queries cho Loki:**

#### **Error Logs:**
```logql
{job="kubernetes-pods"} |= "error"
```

#### **Logs by Namespace:**
```logql
sum by (namespace) (count_over_time({job="kubernetes-pods"}[5m]))
```

#### **Application Logs:**
```logql
{job="kubernetes-pods", app="your-app"}
```

#### **Container Logs:**
```logql
{job="kubernetes-pods", container="your-container"}
```

### 🔍 **Drilldown Features:**

#### **Enable Drilldown:**
1. Vào panel settings
2. Tab **Field**
3. Enable **Override** → **Add override** → **Add field override**
4. **Properties** → **Links** → **Add link**
5. **Type**: **Dashboard**
6. **Dashboard**: Chọn dashboard target
7. **Parameters**: Thêm variables

#### **Example Drilldown:**
```yaml
# From namespace overview to specific namespace logs
Parameters:
  var-namespace: ${__value.raw}
  var-app: All
```

### 📊 **Recommended Dashboard Stack:**

#### **Core Monitoring:**
1. **Kubernetes Cluster Monitoring** (ID: 315)
2. **Node Exporter Full** (ID: 1860)
3. **Kubernetes Logs Dashboard** (Custom)
4. **Loki Performance Dashboard** (Custom)

#### **Application Monitoring:**
1. **Application-specific dashboards**
2. **Database monitoring** (nếu có)
3. **Custom business metrics**

### 🚨 **Alerting Setup:**

#### **Log-based Alerts:**
```yaml
# Alert khi có quá nhiều error logs
groups:
  - name: log-alerts
    rules:
      - alert: HighErrorRate
        expr: sum(rate({job="kubernetes-pods"} |= "error"[5m])) > 10
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High error rate detected"
```

### 🔧 **Troubleshooting:**

#### **Dashboard không load:**
```bash
# Kiểm tra ConfigMap
kubectl get configmap -n monitoring | grep grafana

# Kiểm tra labels
kubectl get configmap grafana-dashboards -n monitoring --show-labels

# Kiểm tra logs
kubectl logs -n monitoring -l app=grafana -c grafana-sc-dashboards
```

#### **Drilldown không hoạt động:**
```bash
# Kiểm tra Loki config
kubectl get configmap loki-config -n monitoring -o yaml | grep volume_enabled

# Restart Loki nếu cần
kubectl rollout restart deployment loki -n monitoring
```

### 📝 **Next Steps:**

1. **Import recommended dashboards** từ Grafana.com
2. **Customize dashboards** theo nhu cầu
3. **Setup alerting rules** cho logs và metrics
4. **Create application-specific dashboards**
5. **Setup drilldown navigation** giữa các dashboard

---

**Status**: ✅ **READY**  
**Drilldown**: ✅ **ENABLED**  
**Next**: Import và customize dashboards 