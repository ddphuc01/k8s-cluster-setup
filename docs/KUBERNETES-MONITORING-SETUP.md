# Kubernetes Monitoring Stack Setup Guide

## Tổng quan

Tài liệu này hướng dẫn triển khai **monitoring stack** hoàn chỉnh cho Kubernetes cluster, bao gồm:

- **Prometheus** - Metrics collection và storage
- **Grafana** - Visualization và dashboards
- **Alertmanager** - Alert notification
- **MinIO** - Object storage (S3-compatible)
- **Promtail** - Log collection
- **NGINX Ingress Controller** - Traffic routing

## Kiến trúc hệ thống

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Prometheus    │    │    Grafana      │    │  Alertmanager   │
│   (Metrics)     │    │ (Visualization) │    │  (Alerts)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  NGINX Ingress  │
                    │   Controller    │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │     MinIO       │
                    │ (Object Storage)│
                    └─────────────────┘
```

## Yêu cầu hệ thống

- Kubernetes cluster (v1.24+)
- Helm (v3.0+)
- kubectl
- MetalLB (cho LoadBalancer services)
- NGINX Ingress Controller

## Bước 1: Chuẩn bị môi trường

### 1.1. Kiểm tra cluster
```bash
kubectl get nodes
kubectl get pods -A
```

### 1.2. Thêm Helm repositories
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add minio https://charts.min.io/
helm repo update
```

### 1.3. Tạo namespace
```bash
kubectl create namespace monitoring
```

## Bước 2: Cài đặt StorageClass

### 2.1. Cài đặt local-path-provisioner
```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
```

### 2.2. Kiểm tra StorageClass
```bash
kubectl get storageclass
```

## Bước 3: Cài đặt MinIO (Object Storage)

### 3.1. Cài đặt MinIO
```bash
helm install minio minio/minio \
  --namespace monitoring \
  --set auth.rootUser=minioadmin \
  --set auth.rootPassword=minioadmin123 \
  --set mode=standalone \
  --set persistence.size=5Gi \
  --set persistence.storageClass=local-path \
  --set resources.requests.memory=256Mi \
  --set resources.requests.cpu=100m \
  --set resources.limits.memory=512Mi \
  --set resources.limits.cpu=200m \
  --set service.type=LoadBalancer \
  --wait --timeout=5m
```

### 3.2. Kiểm tra MinIO
```bash
kubectl get pods -n monitoring | grep minio
kubectl get svc -n monitoring | grep minio
```

## Bước 4: Cài đặt Prometheus Stack

### 4.1. Cài đặt kube-prometheus-stack
```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.enabled=true \
  --set grafana.adminPassword=admin123 \
  --set grafana.service.type=LoadBalancer \
  --set grafana.ingress.enabled=true \
  --set grafana.ingress.hosts[0]=grafana.local \
  --set grafana.ingress.ingressClassName=nginx \
  --set alertmanager.enabled=true \
  --set alertmanager.alertmanagerSpec.service.type=LoadBalancer \
  --wait --timeout=10m
```

### 4.2. Kiểm tra Prometheus stack
```bash
kubectl get pods -n monitoring
helm list -n monitoring
```

## Bước 5: Cài đặt Promtail (Log Collection)

### 5.1. Cài đặt Promtail
```bash
helm install promtail grafana/promtail \
  --namespace monitoring \
  --set loki.serviceName=loki \
  --set loki.servicePort=3100 \
  --wait --timeout=5m
```

### 5.2. Kiểm tra Promtail
```bash
kubectl get pods -n monitoring | grep promtail
```

## Bước 6: Cấu hình Ingress

### 6.1. Tạo Ingress cho Prometheus
```bash
kubectl apply -f manifests/monitoring/prometheus-ingress.yaml
```

### 6.2. Tạo Ingress cho Alertmanager
```bash
kubectl apply -f manifests/monitoring/alertmanager-ingress.yaml
```

### 6.3. Cập nhật /etc/hosts
```bash
echo "192.168.56.101 prometheus.local alertmanager.local minio.local minio-console.local" | sudo tee -a /etc/hosts
```

## Bước 7: Cấu hình Alert Rules

### 7.1. Áp dụng Prometheus Rules
```bash
kubectl apply -f manifests/monitoring/prometheus-rules.yaml
```

### 7.2. Cấu hình Alertmanager
```bash
kubectl apply -f manifests/monitoring/alertmanager-config.yaml
```

## Bước 8: Cấu hình Grafana

### 8.1. Áp dụng Dashboards
```bash
kubectl apply -f manifests/monitoring/grafana-dashboards.yaml
```

### 8.2. Cấu hình Datasources
```bash
kubectl apply -f manifests/monitoring/grafana-datasources.yaml
```

## Bước 9: Kiểm tra và Test

### 9.1. Chạy script kiểm tra
```bash
./scripts/check-monitoring-stack.sh
```

### 9.2. Test kết nối thủ công
```bash
# Test Grafana
curl -I -H "Host: grafana.local" http://192.168.56.101:30098

# Test Prometheus
curl -I -H "Host: prometheus.local" http://192.168.56.101:32702

# Test Alertmanager
curl -I -H "Host: alertmanager.local" http://192.168.56.101:32702

# Test MinIO
curl -I http://192.168.56.201:9000
```

## Truy cập các dịch vụ

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://grafana.local | admin/admin123 |
| Prometheus | http://prometheus.local | - |
| Alertmanager | http://alertmanager.local | - |
| MinIO | http://192.168.56.201:9000 | minioadmin/minioadmin123 |
| MinIO Console | http://minio-console.local:9001 | minioadmin/minioadmin123 |

## Cấu hình Alertmanager

### Slack Integration
```yaml
receivers:
  - name: 'slack-notifications'
    slack_configs:
      - channel: '#alerts'
        api_url: 'https://hooks.slack.com/services/YOUR_WEBHOOK_URL'
```

### Email Integration
```yaml
receivers:
  - name: 'email-notifications'
    email_configs:
      - to: 'admin@yourdomain.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'your-email@gmail.com'
        auth_password: 'your-app-password'
```

### Webhook Integration
```yaml
receivers:
  - name: 'webhook-notifications'
    webhook_configs:
      - url: 'http://your-webhook-server:8080/alerts'
```

## Monitoring Best Practices

### 1. Resource Management
- Đặt resource limits cho tất cả pods
- Sử dụng HPA (Horizontal Pod Autoscaler) khi cần
- Monitor resource usage thường xuyên

### 2. Alert Rules
- Tạo alert rules cho critical metrics
- Sử dụng severity levels (warning, critical)
- Cấu hình alert grouping và inhibition

### 3. Security
- Sử dụng RBAC cho service accounts
- Enable network policies
- Rotate credentials định kỳ

### 4. Backup và Recovery
- Backup Prometheus data
- Backup Grafana dashboards
- Test recovery procedures

## Troubleshooting

### Common Issues

#### 1. Pod không start
```bash
kubectl describe pod <pod-name> -n monitoring
kubectl logs <pod-name> -n monitoring
```

#### 2. Ingress không hoạt động
```bash
kubectl get ingress -n monitoring
kubectl describe ingress <ingress-name> -n monitoring
```

#### 3. Storage issues
```bash
kubectl get pvc -n monitoring
kubectl get pv
```

#### 4. Network connectivity
```bash
kubectl get svc -n monitoring
kubectl get endpoints -n monitoring
```

### Useful Commands

```bash
# Kiểm tra trạng thái tổng thể
kubectl get all -n monitoring

# Xem logs của service
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus

# Port forward để debug
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Kiểm tra metrics
kubectl top pods -n monitoring
kubectl top nodes
```

## Maintenance

### 1. Updates
```bash
# Update Helm charts
helm repo update
helm upgrade prometheus prometheus-community/kube-prometheus-stack -n monitoring
helm upgrade minio minio/minio -n monitoring
```

### 2. Backup
```bash
# Backup Grafana dashboards
kubectl get configmap grafana-dashboards -n monitoring -o yaml > backup-dashboards.yaml

# Backup Prometheus rules
kubectl get prometheusrule -n monitoring -o yaml > backup-rules.yaml
```

### 3. Cleanup
```bash
# Uninstall monitoring stack
helm uninstall prometheus -n monitoring
helm uninstall minio -n monitoring
helm uninstall promtail -n monitoring
kubectl delete namespace monitoring
```

## Kết luận

Monitoring stack đã được triển khai thành công với:
- ✅ Prometheus metrics collection
- ✅ Grafana visualization
- ✅ Alertmanager notifications
- ✅ MinIO object storage
- ✅ Promtail log collection
- ✅ NGINX Ingress routing

Hệ thống sẵn sàng cho production use với các best practices đã được áp dụng.

---

**Lưu ý:** Đây là tài liệu hướng dẫn cơ bản. Để production, cần bổ sung thêm security, backup, và monitoring cho chính monitoring stack. 