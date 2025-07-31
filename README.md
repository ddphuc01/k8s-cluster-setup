# Kubernetes Cluster Setup với Calico Networking

## Tổng quan
Project này cài đặt Kubernetes cluster sử dụng Kubespray với Calico CNI trên 2 node:
- **Master Node**: 192.168.56.101
- **Worker Node**: 192.168.56.102

## Kiến trúc hệ thống
```
┌─────────────────┐    ┌─────────────────┐
│   Master Node   │    │   Worker Node   │
│ 192.168.56.101  │    │ 192.168.56.102  │
│                 │    │                 │
│ - API Server    │    │ - Kubelet       │
│ - etcd          │    │ - kube-proxy    │
│ - Controller    │    │ - Calico Node   │
│ - Scheduler     │    │                 │
└─────────────────┘    └─────────────────┘
         │                       │
         └─────── Calico Network ───────┘
```

## Các thành phần chính
- **Kubernetes**: v1.29.15
- **Container Runtime**: containerd
- **CNI**: Calico v3.26.4
- **Load Balancer**: MetalLB (tùy chọn)
- **Ingress Controller**: NGINX (tùy chọn)
- **Management Platform**: Rancher (tùy chọn)

## Cấu trúc thư mục
```
k8s-cluster-setup/
├── README.md                 # Tài liệu này
├── inventory/                # Cấu hình Ansible inventory
│   ├── hosts.yml            # Danh sách hosts
│   └── group_vars/          # Biến cấu hình
├── scripts/                  # Scripts cài đặt
│   ├── pre-install.sh       # Chuẩn bị hệ thống
│   ├── install-kubespray.sh # Cài đặt Kubespray
│   └── post-install.sh      # Cấu hình sau cài đặt
└── docs/                     # Tài liệu chi tiết
    ├── installation.md      # Hướng dẫn cài đặt
    ├── configuration.md     # Cấu hình chi tiết
    └── troubleshooting.md   # Xử lý sự cố
```

## Yêu cầu hệ thống
- Ubuntu 20.04+ hoặc CentOS 8+
- RAM: Tối thiểu 2GB cho mỗi node
- CPU: Tối thiểu 2 cores cho mỗi node
- Disk: Tối thiểu 20GB cho mỗi node
- Network: Kết nối giữa các node

## Quick Start
```bash
# 1. Clone và cài đặt
git clone <repository>
cd k8s-cluster-setup

# 2. Chạy script cài đặt
./install.sh

# 3. Kiểm tra cluster
kubectl get nodes
kubectl get pods -A

# 4. Cài đặt Rancher (Tùy chọn)
./scripts/install-rancher-complete.sh
```

## Liên hệ
DevOps Engineer - Kubernetes Cluster Setup 