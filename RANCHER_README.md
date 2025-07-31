# 🐄 Rancher Management Platform

## Tổng quan

Rancher là một platform quản lý Kubernetes toàn diện, cung cấp giao diện web để quản lý nhiều Kubernetes clusters một cách dễ dàng và hiệu quả.

## 🚀 Cài đặt nhanh

### Cài đặt hoàn chỉnh (Khuyến nghị)
```bash
./scripts/install-rancher-complete.sh
```

### Cài đặt từng bước
```bash
# 1. Cài đặt MetalLB Load Balancer
./scripts/install-metallb.sh

# 2. Cài đặt NGINX Ingress Controller
./scripts/install-ingress.sh

# 3. Cài đặt Rancher
./scripts/install-rancher.sh
```

## 📋 Thông tin truy cập

### URL truy cập
```
https://rancher.192.168.56.101.nip.io
```

### Thông tin đăng nhập
- **Username**: `admin`
- **Password**: `admin123`

## 🏗️ Kiến trúc

```
┌─────────────────────────────────────────────────────────┐
│                    Rancher UI                          │
│              https://rancher.192.168.56.101.nip.io     │
└─────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────┐
│                NGINX Ingress Controller                │
│                    (ingress-nginx)                     │
└─────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────┐
│                    Rancher Server                      │
│                   (cattle-system)                      │
└─────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────┐
│                Kubernetes Cluster                      │
│              (master + worker nodes)                   │
└─────────────────────────────────────────────────────────┘
```

## 🔧 Các tính năng chính

### 1. Cluster Management
- Quản lý nhiều Kubernetes clusters
- Deploy và quản lý clusters từ xa
- Monitoring cluster health

### 2. Application Management
- Deploy applications thông qua UI
- Quản lý Helm charts
- Application catalogs

### 3. User Management
- RBAC (Role-Based Access Control)
- Multi-tenancy support
- User authentication và authorization

### 4. Security
- Network policies
- Pod security policies
- Audit logging

### 5. Monitoring & Logging
- Built-in monitoring
- Log aggregation
- Alert management

## 📁 Scripts

### `scripts/install-rancher-complete.sh`
Script cài đặt hoàn chỉnh tất cả components:
- MetalLB Load Balancer
- NGINX Ingress Controller
- Rancher Management Platform

### `scripts/install-metallb.sh`
Cài đặt MetalLB Load Balancer:
- IP Pool: 192.168.56.200-192.168.56.250
- L2 Advertisement mode

### `scripts/install-ingress.sh`
Cài đặt NGINX Ingress Controller:
- Namespace: ingress-nginx
- Service: ingress-nginx-controller

### `scripts/install-rancher.sh`
Cài đặt Rancher Management Platform:
- Namespace: cattle-system
- Hostname: rancher.192.168.56.101.nip.io
- TLS: Let's Encrypt

## 🛠️ Các lệnh hữu ích

### Kiểm tra trạng thái
```bash
# Kiểm tra MetalLB
kubectl get pods -n metallb-system
kubectl get ipaddresspools -n metallb-system

# Kiểm tra Ingress Controller
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Kiểm tra Rancher
kubectl get pods -n cattle-system
kubectl get ingress -n cattle-system
```

### Quản lý Rancher
```bash
# Xem logs Rancher
kubectl logs -n cattle-system -l app=rancher

# Scale Rancher
kubectl scale deployment rancher -n cattle-system --replicas=3

# Backup Rancher
kubectl get all -n cattle-system -o yaml > rancher-backup.yaml
```

### Troubleshooting
```bash
# Xem logs chi tiết
kubectl logs -n cattle-system -l app=rancher -f
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller -f

# Kiểm tra events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

## 🔒 Bảo mật

### Best Practices
1. **Thay đổi password mặc định** ngay sau khi cài đặt
2. **Cấu hình RBAC** cho users và groups
3. **Sử dụng HTTPS** cho tất cả communications
4. **Backup định kỳ** Rancher data
5. **Monitor logs** để phát hiện vấn đề

### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: rancher-network-policy
  namespace: cattle-system
spec:
  podSelector:
    matchLabels:
      app: rancher
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 443
```

## 📊 Monitoring

### Prometheus Integration
Rancher có thể tích hợp với Prometheus để monitoring:

```bash
# Cài đặt Prometheus Operator
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/kube-prometheus/main/manifests/setup/0-namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/kube-prometheus/main/manifests/setup/
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/kube-prometheus/main/manifests/
```

### Grafana Dashboard
- URL: `http://grafana.192.168.56.101.nip.io`
- Username: `admin`
- Password: `admin`

## 🗑️ Uninstall

### Uninstall Rancher
```bash
helm uninstall rancher -n cattle-system
kubectl delete namespace cattle-system
```

### Uninstall Ingress Controller
```bash
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml
```

### Uninstall MetalLB
```bash
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
```

## 📚 Tài liệu tham khảo

### Project Documentation
- `docs/rancher-installation.md` - Hướng dẫn cài đặt chi tiết
- `docs/configuration.md` - Cấu hình chi tiết
- `docs/troubleshooting.md` - Xử lý sự cố

### External Resources
- [Rancher Documentation](https://docs.rancher.com/)
- [Rancher GitHub](https://github.com/rancher/rancher)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [MetalLB Documentation](https://metallb.universe.tf/)

## 🎯 Kết luận

Rancher cung cấp một platform quản lý Kubernetes toàn diện với:
- ✅ Giao diện web thân thiện
- ✅ Quản lý multi-cluster
- ✅ Application management
- ✅ Security và monitoring
- ✅ Backup và disaster recovery

**Rancher đã sẵn sàng để quản lý Kubernetes cluster! 🚀** 