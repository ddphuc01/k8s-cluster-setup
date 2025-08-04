# Kubernetes Cluster Setup với Complete Monitoring Stack

## 🎯 Tổng quan dự án

Dự án này cung cấp giải pháp hoàn chỉnh để triển khai Kubernetes cluster với monitoring stack production-ready bao gồm Prometheus, Grafana, Loki, và AlertManager.

## ✨ Tính năng chính

- **🚀 Tự động hóa hoàn toàn**: Cài đặt K8s cluster chỉ với một lệnh
- **📊 Monitoring toàn diện**: Prometheus + Grafana + AlertManager
- **📝 Log tập trung**: Loki + Promtail cho log aggregation
- **🔒 Bảo mật**: SSL/TLS certificates tự động
- **⚡ Load Balancing**: MetalLB cho bare-metal environments
- **🎛️ Quản lý dễ dàng**: Rancher UI (tùy chọn)

## 🏗️ Kiến trúc hệ thống

```
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                           │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   Master    │  │   Worker    │  │   Worker    │            │
│  │   Node      │  │   Node 1    │  │   Node 2    │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Monitoring Namespace                       │   │
│  │                                                         │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    │   │
│  │  │Prometheus│  │ Grafana │  │   Loki  │  │Promtail │    │   │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘    │   │
│  │                                                         │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    │   │
│  │  │AlertMgr │  │Node Exp │  │KubeState│  │  MinIO  │    │   │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘    │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## 📋 Yêu cầu hệ thống

### Phần cứng tối thiểu
- **Master Node**: 2 CPU, 4GB RAM, 50GB disk
- **Worker Nodes**: 2 CPU, 4GB RAM, 50GB disk mỗi node
- **Network**: Kết nối internet ổn định

### Hệ điều hành được hỗ trợ
- Ubuntu 20.04/22.04 LTS
- CentOS 7/8
- Rocky Linux 8/9
- Debian 10/11

### Phần mềm cần thiết
- Python 3.6+
- Ansible 2.9+
- SSH access đến tất cả nodes
- Sudo privileges

## 🚀 Cài đặt nhanh

### Bước 1: Chuẩn bị môi trường

```bash
# Clone repository
git clone https://github.com/ddphuc01/k8s-cluster-setup.git
cd k8s-cluster-setup

# Cấp quyền thực thi
chmod +x install.sh
chmod +x scripts/*.sh
```

### Bước 2: Cấu hình inventory

Chỉnh sửa file `inventory/hosts.yml`:

```yaml
all:
  hosts:
    master:
      ansible_host: 192.168.1.10
      ip: 192.168.1.10
      access_ip: 192.168.1.10
    worker1:
      ansible_host: 192.168.1.11
      ip: 192.168.1.11
      access_ip: 192.168.1.11
    worker2:
      ansible_host: 192.168.1.12
      ip: 192.168.1.12
      access_ip: 192.168.1.12
  children:
    kube_control_plane:
      hosts:
        master:
    kube_node:
      hosts:
        worker1:
        worker2:
    etcd:
      hosts:
        master:
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
    calico_rr:
      hosts: {}
```

### Bước 3: Chạy cài đặt

```bash
# Cài đặt cluster cơ bản
./install.sh

# Hoặc cài đặt với monitoring stack
./install.sh --with-monitoring

# Hoặc cài đặt đầy đủ với Rancher
./install.sh --full-stack
```

## 📊 Truy cập Monitoring Stack

Sau khi cài đặt thành công, bạn có thể truy cập:

### Grafana Dashboard
```bash
# Lấy URL và credentials
kubectl get ingress -n monitoring grafana-ingress
kubectl get secret -n monitoring grafana-admin-secret -o jsonpath="{.data.admin-password}" | base64 -d
```

- **URL**: `https://grafana.your-domain.com`
- **Username**: `admin`
- **Password**: Lấy từ lệnh trên

### Prometheus
```bash
kubectl get ingress -n monitoring prometheus-ingress
```

- **URL**: `https://prometheus.your-domain.com`

### AlertManager
```bash
kubectl get ingress -n monitoring alertmanager-ingress
```

- **URL**: `https://alertmanager.your-domain.com`

## 🎛️ Truy cập Rancher Management Platform

### Thông tin truy cập
```bash
# Kiểm tra trạng thái Rancher
./scripts/rancher-status.sh

# Lấy Bootstrap Password
kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}'
```

- **URL**: `https://rancher.local`
- **External IP**: `192.168.56.102`
- **Username**: `admin`
- **Password**: Bootstrap password từ lệnh trên

### Cấu hình DNS local
```bash
# Thêm vào /etc/hosts
echo "192.168.56.102 rancher.local" | sudo tee -a /etc/hosts
```

### Tính năng Rancher
- **Multi-cluster Management**: Quản lý nhiều K8s clusters
- **Application Catalog**: Deploy apps qua Helm charts
- **User Management**: RBAC và authentication
- **Monitoring Integration**: Tích hợp với Prometheus/Grafana
- **Security Policies**: Network policies, RBAC

## 🔧 Cấu hình nâng cao

### Tùy chỉnh Monitoring

Chỉnh sửa các file trong `manifests/monitoring/`:

- `prometheus-rules.yaml`: Cấu hình alert rules
- `alertmanager-config.yaml`: Cấu hình notification channels
- `grafana-dashboards-config.yaml`: Import custom dashboards

### Cấu hình SSL/TLS

```bash
# Cài đặt cert-manager
./scripts/install-cert-manager.sh

# Cấu hình Let's Encrypt
kubectl apply -f manifests/cert-manager/
```

### Backup và Restore

```bash
# Backup ETCD
./scripts/backup-etcd.sh

# Backup Persistent Volumes
./scripts/backup-pvs.sh

# Restore từ backup
./scripts/restore-cluster.sh /path/to/backup
```

## 🛠️ Scripts hữu ích

### Kiểm tra trạng thái
```bash
./scripts/check-monitoring-stack.sh    # Kiểm tra monitoring
./scripts/rancher-status.sh           # Kiểm tra Rancher
```

### Bảo trì
```bash
./scripts/cleanup-cert-manager.sh     # Dọn dẹp certificates
./scripts/fix-python-env.sh          # Sửa Python environment
```

### Cài đặt thành phần riêng lẻ
```bash
./scripts/install-metallb.sh         # Cài MetalLB
./scripts/install-ingress.sh         # Cài NGINX Ingress
./scripts/install-monitoring-stack.sh # Cài monitoring stack
```

## 📋 Tài liệu chi tiết

- [Hướng dẫn cài đặt chi tiết](docs/installation.md)
- [Cấu hình hệ thống](docs/configuration.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Cài đặt Rancher](docs/rancher-installation.md)
- [Hướng dẫn sử dụng Rancher](docs/rancher-access-guide.md)
- [Grafana Dashboards](GRAFANA_DASHBOARDS_GUIDE.md)
- [Loki Deployment](LOKI_DEPLOYMENT_SUMMARY.md)

## 🔍 Troubleshooting

### Lỗi thường gặp

#### 1. SSH Connection Failed
```bash
# Kiểm tra SSH connectivity
ansible all -i inventory/hosts.yml -m ping

# Cấu hình SSH keys
./scripts/configure-sudo.sh
```

#### 2. Pod không start được
```bash
# Kiểm tra logs
kubectl logs -n kube-system <pod-name>

# Kiểm tra resources
kubectl describe node
kubectl top nodes
```

#### 3. Monitoring stack không hoạt động
```bash
# Kiểm tra trạng thái
./scripts/check-monitoring-stack.sh

# Restart monitoring pods
kubectl rollout restart deployment -n monitoring
```

### Logs và Debug

```bash
# Xem logs cài đặt
tail -f /var/log/kubespray.log

# Debug Ansible
export ANSIBLE_LOG_PATH=/tmp/ansible.log
export ANSIBLE_DEBUG=1
```

## 🤝 Đóng góp

1. Fork repository
2. Tạo feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Tạo Pull Request

## 📄 License

Dự án này được phân phối dưới MIT License. Xem `LICENSE` để biết thêm thông tin.

## 🆘 Hỗ trợ

- **Issues**: [GitHub Issues](https://github.com/ddphuc01/k8s-cluster-setup/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ddphuc01/k8s-cluster-setup/discussions)
- **Email**: ddphuc01@gmail.com

## 🏷️ Phiên bản

- **Current**: v2.0.0
- **Kubernetes**: 1.28+
- **Kubespray**: 2.23+
- **Calico**: 3.26+

---

⭐ **Nếu dự án này hữu ích, hãy cho chúng tôi một star!** ⭐
