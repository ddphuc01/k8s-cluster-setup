# Loki Deployment Summary

## ✅ Triển khai thành công Loki trên Kubernetes

### 📋 Tổng quan
- **Loki Version**: 2.9.3
- **Deployment Method**: Manual YAML manifests
- **Storage**: Filesystem với PersistentVolume (10Gi)
- **Namespace**: monitoring
- **Mode**: Single Binary

### 🏗️ Các thành phần đã triển khai

#### 1. Loki Core Components
- **Deployment**: `loki` (1 replica)
- **Service**: `loki` (ClusterIP, ports 3100, 9096)
- **PVC**: `loki-pvc` (10Gi, local-path storage class)
- **ConfigMap**: `loki-config` (cấu hình Loki)

#### 2. Networking
- **Ingress**: `loki-ingress` (nginx, host: loki.local)
- **Access**: http://loki.local (cần thêm vào /etc/hosts)

#### 3. Integration với Stack hiện tại
- **Promtail**: ✅ Đã cấu hình gửi logs đến Loki
- **Grafana**: ✅ Đã cấu hình datasource Loki
- **Prometheus**: ✅ Đang chạy song song

### 📁 Files được tạo

```
k8s-cluster-setup/manifests/monitoring/
├── loki-deployment-manual.yaml      # Deployment chính
├── loki-config-simple.yaml          # ConfigMap đơn giản
└── loki-config.yaml                 # ConfigMap gốc
```

### 🔧 Cấu hình chính

#### Loki Config (loki-config-simple.yaml)
- **Auth**: Disabled
- **Storage**: Filesystem
- **Retention**: 744h (31 days)
- **Compaction**: Enabled
- **Limits**: Được tối ưu cho môi trường development

#### Service Configuration
- **Type**: ClusterIP
- **Ports**: 
  - 3100 (HTTP API)
  - 9096 (gRPC)

### 🌐 Access Information

#### Internal Access
```bash
# Port-forward để test
kubectl port-forward -n monitoring svc/loki 3100:3100

# Test API
curl http://localhost:3100/ready
```

#### External Access
```bash
# Thêm vào /etc/hosts
echo "192.168.56.102 loki.local" | sudo tee -a /etc/hosts

# Access qua ingress
curl http://loki.local
```

### 🔗 Integration với Grafana

#### Datasource Configuration
```yaml
- name: Loki
  type: loki
  url: http://loki:3100
  access: proxy
```

#### Access Grafana
- **URL**: http://grafana.local (cần thêm vào /etc/hosts)
- **Datasources**: Prometheus + Loki
- **Dashboards**: Có sẵn cho logs và metrics

### 📊 Monitoring Stack Status

```bash
# Kiểm tra trạng thái
kubectl get pods -n monitoring | grep -E "(loki|promtail|grafana|prometheus)"

# Kiểm tra services
kubectl get svc -n monitoring | grep -E "(loki|grafana|prometheus)"

# Kiểm tra ingress
kubectl get ingress -n monitoring
```

### 🚀 Next Steps

1. **Tạo Log Dashboards** trong Grafana
2. **Cấu hình Alerting Rules** cho logs
3. **Tối ưu hóa Retention Policy** theo nhu cầu
4. **Setup Log Aggregation** cho applications
5. **Monitoring Loki Performance**

### 🔍 Troubleshooting

#### Kiểm tra logs
```bash
# Loki logs
kubectl logs -n monitoring -l app=loki

# Promtail logs
kubectl logs -n monitoring -l app=promtail

# Grafana logs
kubectl logs -n monitoring -l app=grafana
```

#### Kiểm tra cấu hình
```bash
# Loki config
kubectl get configmap loki-config -n monitoring -o yaml

# Promtail config
helm get values promtail -n monitoring
```

### 📈 Performance Metrics

- **Memory Usage**: ~256Mi (request) / 512Mi (limit)
- **CPU Usage**: ~100m (request) / 500m (limit)
- **Storage**: 10Gi persistent volume
- **Replicas**: 1 (single binary mode)

### 🎯 Benefits

1. **Centralized Logging**: Tất cả logs từ cluster được tập trung
2. **Integration**: Tích hợp hoàn hảo với Prometheus + Grafana
3. **Scalability**: Có thể scale theo nhu cầu
4. **Cost-effective**: Sử dụng filesystem storage thay vì S3
5. **Easy Management**: Single binary mode đơn giản

---

**Deployment Date**: 31/07/2025  
**Status**: ✅ Active  
**Maintainer**: DevOps Team 