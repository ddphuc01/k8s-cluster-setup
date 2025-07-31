# 🚀 Kubernetes Cluster Setup với Calico Networking

[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29.15-blue?logo=kubernetes)](https://kubernetes.io/)
[![Calico](https://img.shields.io/badge/Calico-3.26.4-orange?logo=calico)](https://www.tigera.io/project-calico/)
[![Kubespray](https://img.shields.io/badge/Kubespray-Latest-green?logo=ansible)](https://kubespray.io/)
[![Rancher](https://img.shields.io/badge/Rancher-Latest-purple?logo=rancher)](https://rancher.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Production-ready Kubernetes cluster setup với Calico networking, Rancher management platform và comprehensive automation scripts.**

## 📋 Tổng quan

Project này cung cấp giải pháp hoàn chỉnh để cài đặt và quản lý Kubernetes cluster trên bare metal hoặc VM với:

- ✅ **Kubernetes v1.29.15** - Container orchestration platform
- ✅ **Calico v3.26.4** - Advanced networking và security
- ✅ **Kubespray** - Production-ready Kubernetes installer
- ✅ **Rancher** - Multi-cluster management platform
- ✅ **MetalLB** - Bare metal load balancer
- ✅ **NGINX Ingress Controller** - Ingress management
- ✅ **Ubuntu 24.04+ Support** - Modern OS compatibility

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
┌─────────────────┐    ┌─────────────────┐
│   Master Node   │    │   Worker Node   │
│ 192.168.56.101  │    │ 192.168.56.102  │
│                 │    │                 │
│ ✅ Ready        │    │ ✅ Ready        │
│ control-plane   │    │ worker          │
└─────────────────┘    └─────────────────┘
         │                       │
         └─────── Calico Network ───────┘
```

## 🚀 Quick Start

### Yêu cầu hệ thống
- **OS**: Ubuntu 20.04+ hoặc CentOS 8+
- **RAM**: Tối thiểu 2GB cho mỗi node
- **CPU**: Tối thiểu 2 cores cho mỗi node
- **Disk**: Tối thiểu 20GB cho mỗi node
- **Network**: Kết nối giữa các node

### Cài đặt nhanh

```bash
# 1. Clone repository
git clone https://github.com/yourusername/k8s-cluster-setup.git
cd k8s-cluster-setup

# 2. Cài đặt Kubernetes cluster
./install.sh

# 3. Kiểm tra cluster
kubectl get nodes
kubectl get pods --all-namespaces

# 4. Cài đặt Rancher (Tùy chọn)
./scripts/install-rancher-complete.sh
```

### Truy cập Rancher
- **URL**: `https://rancher.192.168.56.101.nip.io`
- **Username**: `admin`
- **Password**: `admin123`

## 📁 Cấu trúc Project

```
k8s-cluster-setup/
├── 📄 README.md                    # Tài liệu chính
├── 📄 GITHUB_README.md             # README cho GitHub
├── 📄 QUICK_START.md               # Hướng dẫn nhanh
├── 📄 PROJECT_SUMMARY.md           # Tóm tắt project
├── 📄 INSTALLATION_SUCCESS.md      # Trạng thái cài đặt
├── 📄 RANCHER_README.md            # Hướng dẫn Rancher
├── 📄 PYTHON_ENV_FIX.md            # Fix Python environment
├── 📁 inventory/                   # Ansible inventory
│   ├── hosts.yml                   # Hosts configuration
│   └── group_vars/                 # Group variables
│       └── k8s_cluster.yml         # Cluster configuration
├── 📁 scripts/                     # Automation scripts
│   ├── install.sh                  # Main installation script
│   ├── pre-install.sh              # System preparation
│   ├── install-kubespray.sh        # Kubespray installation
│   ├── post-install.sh             # Post-installation config
│   ├── setup-worker.sh             # Worker node setup
│   ├── install-rancher-complete.sh # Complete Rancher setup
│   ├── install-rancher.sh          # Rancher installation
│   ├── install-metallb.sh          # MetalLB installation
│   ├── install-ingress.sh          # Ingress controller
│   ├── fix-python-env.sh           # Python environment fix
│   ├── test-python-env.sh          # Python environment test
│   └── configure-sudo.sh           # Sudo configuration
└── 📁 docs/                        # Documentation
    ├── installation.md             # Installation guide
    ├── configuration.md            # Configuration guide
    ├── troubleshooting.md          # Troubleshooting guide
    └── rancher-installation.md     # Rancher installation guide
```

## 🔧 Tính năng chính

### Kubernetes Cluster
- **Multi-node setup** với master và worker nodes
- **High availability** với etcd clustering
- **Security hardening** với RBAC và network policies
- **Resource management** với resource quotas và limits

### Networking
- **Calico CNI** với advanced networking features
- **Network policies** cho pod-to-pod communication
- **IPAM** với flexible IP pool management
- **BGP support** cho enterprise networking

### Management Platform
- **Rancher UI** cho cluster management
- **Multi-cluster support** từ single interface
- **Application catalogs** và Helm charts
- **User management** với RBAC

### Automation
- **Ansible automation** cho consistent deployment
- **Python environment handling** cho Ubuntu 24.04+
- **Comprehensive scripts** cho easy management
- **Error handling** và troubleshooting guides

## 📊 Monitoring & Logging

### Built-in Monitoring
- **Kubernetes metrics** với metrics-server
- **Node monitoring** với kubelet metrics
- **Pod monitoring** với resource usage

### Logging
- **Container logs** với kubectl logs
- **System logs** với journald
- **Application logs** với standard output

## 🔒 Security

### Network Security
- **Network policies** cho pod isolation
- **Calico security** với policy enforcement
- **Ingress/egress rules** cho traffic control

### Access Control
- **RBAC** cho user permissions
- **Service accounts** cho application access
- **TLS certificates** cho secure communication

### Best Practices
- **Security contexts** cho pod security
- **Resource limits** cho resource protection
- **Regular updates** cho security patches

## 🛠️ Maintenance

### Backup & Recovery
```bash
# Backup cluster configuration
kubectl get all --all-namespaces -o yaml > cluster-backup.yaml

# Backup etcd data
sudo docker run --rm -v $(pwd):/backup \
  --network=host \
  -v /etc/kubernetes/pki/etcd:/etc/kubernetes/pki/etcd \
  --env ETCDCTL_API=3 \
  k8s.gcr.io/etcd-amd64:3.4.13-0 \
  etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  snapshot save /backup/etcd-snapshot.db
```

### Updates
```bash
# Update Kubernetes version
kubectl get nodes
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Update Calico
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

## 🐛 Troubleshooting

### Common Issues
- **Python environment errors** - Xem `PYTHON_ENV_FIX.md`
- **Network connectivity** - Kiểm tra Calico pods
- **Resource constraints** - Kiểm tra node resources
- **Certificate issues** - Kiểm tra TLS certificates

### Debug Commands
```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check network
kubectl get pods -n kube-system -l k8s-app=calico-node
calicoctl get ippools

# Check logs
kubectl logs -n kube-system <pod-name>
kubectl describe pod -n kube-system <pod-name>

# Check events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

## 🤝 Contributing

Chúng tôi hoan nghênh mọi đóng góp! Vui lòng:

1. Fork project này
2. Tạo feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Mở Pull Request

### Development Setup
```bash
# Clone repository
git clone https://github.com/yourusername/k8s-cluster-setup.git
cd k8s-cluster-setup

# Create development environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## 📄 License

Project này được phân phối dưới MIT License. Xem file `LICENSE` để biết thêm chi tiết.

## 🙏 Acknowledgments

- [Kubespray](https://kubespray.io/) - Production-ready Kubernetes installer
- [Calico](https://www.tigera.io/project-calico/) - Advanced networking và security
- [Rancher](https://rancher.com/) - Multi-cluster management platform
- [MetalLB](https://metallb.universe.tf/) - Bare metal load balancer

## 📞 Support

- 📧 **Email**: your-email@example.com
- 🐛 **Issues**: [GitHub Issues](https://github.com/yourusername/k8s-cluster-setup/issues)
- 📖 **Documentation**: [Wiki](https://github.com/yourusername/k8s-cluster-setup/wiki)

---

⭐ **Nếu project này hữu ích, hãy cho chúng tôi một star!** ⭐ 