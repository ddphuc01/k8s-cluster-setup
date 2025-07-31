# Tempo Datasource Fix Guide

## 🎯 **Vấn đề đã được khắc phục**

**Vấn đề**: Tempo datasource trong Grafana báo "not found" cho Prometheus và Loki

**Nguyên nhân**: Các datasource không có UID field, dẫn đến Tempo không thể tham chiếu đúng

**Giải pháp**: Đã thêm UID field cho tất cả datasources

---

## ✅ **Cấu hình hiện tại**

### **Datasources với UID đúng:**
```yaml
- name: Prometheus
  uid: prometheus  # ← Đã thêm
  type: prometheus
  url: http://prometheus-kube-prometheus-prometheus:9090
  isDefault: true

- name: Loki
  uid: loki  # ← Đã thêm
  type: loki
  url: http://loki:3100
  isDefault: false

- name: Tempo
  uid: tempo  # ← Đã thêm
  type: tempo
  url: http://tempo:3200
  isDefault: false
```

### **Tempo Correlation đã cấu hình:**
```yaml
jsonData:
  tracesToLogs:
    datasourceUid: loki  # ← Tham chiếu đúng
  tracesToMetrics:
    datasourceUid: prometheus  # ← Tham chiếu đúng
```

---

## 🔍 **Cách kiểm tra trong Grafana**

### **1. Truy cập Grafana**
- URL: http://grafana.local
- Username: `admin`
- Password: Check secret `prometheus-grafana`

### **2. Kiểm tra Data Sources**
1. Vào **Configuration** → **Data Sources**
2. Tìm **Tempo** datasource
3. Click vào **Tempo** để edit
4. Kiểm tra **Trace to logs** và **Trace to metrics** sections

### **3. Kiểm tra Trace to Logs**
- **Data source**: Phải hiển thị "loki" (không phải "loki - not found")
- **Tags**: job, instance, pod, namespace
- **Time shifts**: 1h, -1h

### **4. Kiểm tra Trace to Metrics**
- **Data source**: Phải hiển thị "prometheus" (không phải "prometheus - not found")
- **Tags**: service.name, job
- **Time shifts**: -2m, 2m

---

## 🚀 **Test Tempo Functionality**

### **1. Explore Traces**
1. Vào **Explore**
2. Chọn **Tempo** datasource
3. Thử query: `{}` (tất cả traces)
4. Hoặc query: `{service.name="your-service"}`

### **2. Test Correlation**
1. Mở một trace
2. Click vào bất kỳ span nào
3. Click **"View Logs"** → Sẽ mở Loki với trace context
4. Click **"View Metrics"** → Sẽ mở Prometheus với trace context

### **3. Service Map**
1. Vào **Explore** → **Tempo**
2. Chọn **Service Map** view
3. Xem service dependencies

---

## 🛠️ **Troubleshooting**

### **Nếu vẫn báo "not found":**

#### **1. Kiểm tra ConfigMap**
```bash
kubectl get configmap grafana-datasources -n monitoring -o yaml
```

#### **2. Kiểm tra Grafana logs**
```bash
kubectl logs -n monitoring -l app=grafana -c grafana --tail=20 | grep -i datasource
```

#### **3. Restart Grafana**
```bash
kubectl rollout restart deployment prometheus-grafana -n monitoring
```

#### **4. Kiểm tra sidecar logs**
```bash
kubectl logs -n monitoring -l app=grafana -c grafana-sc-datasources --tail=5
```

### **Nếu Tempo không hoạt động:**

#### **1. Kiểm tra Tempo pod**
```bash
kubectl get pods -n monitoring | grep tempo
```

#### **2. Kiểm tra Tempo logs**
```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=tempo --tail=10
```

#### **3. Test Tempo API**
```bash
kubectl port-forward -n monitoring svc/tempo 3200:3200 &
curl http://localhost:3200/ready
```

---

## 📊 **Expected Behavior**

### **✅ Khi hoạt động đúng:**
- **Trace to logs**: Hiển thị "loki" (không có "not found")
- **Trace to metrics**: Hiển thị "prometheus" (không có "not found")
- **Service Map**: Hiển thị service dependencies
- **Correlation**: Click vào span → View Logs/Metrics hoạt động

### **❌ Khi có vấn đề:**
- **"not found"**: Datasource UID không đúng
- **"Connection failed"**: Tempo service không accessible
- **"No traces"**: Chưa có traces được gửi đến Tempo

---

## 🎯 **Next Steps**

### **1. Instrument Applications**
```yaml
# Add to your application deployment
env:
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: "http://tempo:4317"
- name: OTEL_SERVICE_NAME
  value: "your-service"
```

### **2. Import Trace Dashboards**
- **Tempo Service Map**: ID 12019
- **Custom Trace Dashboards**: Tạo theo nhu cầu

### **3. Setup Trace-based Alerts**
```yaml
groups:
  - name: trace-alerts
    rules:
      - alert: HighTraceLatency
        expr: histogram_quantile(0.95, sum(rate(traces_spanmetrics_duration_seconds_bucket[5m])) by (le, service_name)) > 1
```

---

## 📞 **Support**

### **Commands để debug:**
```bash
# Check all components
kubectl get pods -n monitoring

# Check datasources
kubectl get configmap -n monitoring | grep datasource

# Check Tempo
kubectl logs -n monitoring -l app.kubernetes.io/name=tempo --tail=10

# Check Grafana
kubectl logs -n monitoring -l app=grafana -c grafana --tail=10
```

### **Documentation:**
- **Tempo Guide**: [TEMPO_DEPLOYMENT_GUIDE.md](TEMPO_DEPLOYMENT_GUIDE.md)
- **Complete Guide**: [MONITORING_STACK_COMPLETE_GUIDE.md](MONITORING_STACK_COMPLETE_GUIDE.md)

---

**Status**: ✅ **FIXED**  
**Last Updated**: 31/07/2025  
**Next**: Test Tempo functionality trong Grafana 