# Hướng dẫn cài đặt Rancher Management Platform

## 🎯 Tổng quan

Rancher là platform quản lý Kubernetes enterprise-grade, cung cấp:
- **Multi-cluster Management**: Quản lý nhiều Kubernetes clusters từ một giao diện
- **Application Catalog**: Deploy applications qua Helm charts
- **User Management**: RBAC và authentication tích hợp
- **Monitoring & Logging**: Tích hợp Prometheus và Grafana
- **Security**: Network policies, pod security policies

## 📋 Yêu cầu hệ thống (Đã xác minh)

### ✅ Kubernetes Cluster hiện tại
```bash
# Cluster info
Kubernetes: v1.29.15
Nodes: 2 (master + worker)
CNI: Calico
Container Runtime: containerd://1.7.11
OS: Ubuntu 24.04.2 LTS

# Network configuration
Master IP: 192.168.56.101
Worker IP: 192.168.56.102
Pod CIDR: 10.233.64.0/18
Service CIDR: 10.233.0.0/18
```

### 🔧 Dependencies (Đã cài đặt)
- ✅ kubectl
- ✅ Helm 3.x
- ✅ NGINX Ingress Controller
- ✅ MetalLB Load Balancer
- ✅ cert-manager

## 🏗️ Kiến trúc Rancher (Đã triển khai)

```
┌─────────────────────────────────────────────────────────────────┐
│                        Rancher UI                              │
│                   https://rancher.local                        │
│                  (External IP: 192.168.56.102)                │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    NGINX Ingress Controller                    │
│                      (ingress-nginx)                           │
│                   LoadBalancer: MetalLB                        │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      cert-manager                              │
│                   (TLS Certificate)                            │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Rancher Server                              │
│                   (cattle-system)                              │
│              3 replicas + webhook                              │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Kubernetes Cluster                            │
│   Master (192.168.56.101) + Worker (192.168.56.102)           │
│              Calico CNI + containerd                           │
└─────────────────────────────────────────────────────────────────┘
```

### 📊 Trạng thái hiện tại
```bash
# Rancher Pods (đang chạy)
rancher-6d45975c97-5862v    2/2 Running
rancher-6d45975c97-dl5kz    2/2 Running  
rancher-6d45975c97-v89z5    2/2 Running
rancher-webhook-xxx         1/1 Running

# Services
rancher                     ClusterIP   10.233.10.152
rancher-webhook            ClusterIP   10.233.40.81

# Ingress
rancher.local              192.168.56.102   80,443
```

## Các bước cài đặt

### Bước 1: Cài đặt hoàn chỉnh (Khuyến nghị)

Chạy script tự động để cài đặt tất cả components:

```bash
./scripts/install-rancher-complete.sh
```

Script này sẽ tự động:
1. Cài đặt MetalLB Load Balancer
2. Cài đặt NGINX Ingress Controller
3. Cài đặt Rancher Management Platform

### Bước 2: Cài đặt từng bước (Tùy chọn)

Nếu muốn cài đặt từng component riêng biệt:

#### 2.1. Cài đặt MetalLB
```bash
./scripts/install-metallb.sh
```

#### 2.2. Cài đặt NGINX Ingress Controller
```bash
./scripts/install-ingress.sh
```

#### 2.3. Cài đặt Rancher
```bash
./scripts/install-rancher.sh
```

## Cấu hình chi tiết

### MetalLB Configuration
```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.56.200-192.168.56.250
```

### NGINX Ingress Controller
- **Namespace**: `ingress-nginx`
- **Service**: `ingress-nginx-controller`
- **Port**: 80, 443

### Rancher Configuration
- **Namespace**: `cattle-system`
- **Hostname**: `rancher.192.168.56.101.nip.io`
- **Username**: `admin`
- **Password**: `admin123`
- **TLS**: Let's Encrypt

## Truy cập Rancher

### URL truy cập
```
https://rancher.192.168.56.101.nip.io
```

### Thông tin đăng nhập
- **Username**: `admin`
- **Password**: `admin123`

### Lưu ý
- Lần đầu truy cập sẽ yêu cầu đặt password mới
- Có thể mất vài phút để Rancher hoàn toàn sẵn sàng
- Nếu không thể truy cập, kiểm tra DNS hoặc thêm entry vào `/etc/hosts`

## Kiểm tra trạng thái

### Kiểm tra MetalLB
```bash
kubectl get pods -n metallb-system
kubectl get ipaddresspools -n metallb-system
```

### Kiểm tra Ingress Controller
```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

### Kiểm tra Rancher
```bash
kubectl get pods -n cattle-system
kubectl get ingress -n cattle-system
```

## Quản lý Rancher

### Các tính năng chính
1. **Cluster Management**: Quản lý nhiều Kubernetes clusters
2. **Application Management**: Deploy và quản lý applications
3. **User Management**: Quản lý users và permissions
4. **Monitoring**: Monitoring và logging
5. **Security**: RBAC, Network Policies

### Các lệnh hữu ích

#### Xem logs Rancher
```bash
kubectl logs -n cattle-system -l app=rancher
```

#### Scale Rancher
```bash
kubectl scale deployment rancher -n cattle-system --replicas=3
```

#### Backup Rancher
```bash
# Backup Rancher data
kubectl get all -n cattle-system -o yaml > rancher-backup.yaml
```

#### Uninstall Rancher
```bash
helm uninstall rancher -n cattle-system
kubectl delete namespace cattle-system
```

## Troubleshooting

### Vấn đề thường gặp

#### 1. Rancher không thể truy cập
```bash
# Kiểm tra ingress
kubectl get ingress -n cattle-system

# Kiểm tra pods
kubectl get pods -n cattle-system

# Kiểm tra logs
kubectl logs -n cattle-system -l app=rancher
```

#### 2. Cert-manager lỗi
```bash
# Kiểm tra cert-manager
kubectl get pods -n cert-manager

# Xem certificates
kubectl get certificates -n cattle-system
```

#### 3. Ingress Controller không hoạt động
```bash
# Kiểm tra ingress controller
kubectl get pods -n ingress-nginx

# Kiểm tra service
kubectl get svc -n ingress-nginx
```

### Logs và Debug

#### Xem logs chi tiết
```bash
# Rancher logs
kubectl logs -n cattle-system -l app=rancher -f

# Ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller -f

# Cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager -f
```

#### Kiểm tra events
```bash
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

## Bảo mật

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

## Monitoring và Logging

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

## Kết luận

Rancher cung cấp một platform quản lý Kubernetes toàn diện với:
- ✅ Giao diện web thân thiện
- ✅ Quản lý multi-cluster
- ✅ Application management
- ✅ Security và monitoring
- ✅ Backup và disaster recovery

Sau khi cài đặt thành công, bạn có thể:
1. Truy cập Rancher UI để quản lý cluster
2. Deploy applications thông qua Rancher
3. Cấu hình monitoring và logging
4. Quản lý users và permissions

**Rancher đã sẵn sàng để sử dụng! 🚀** 