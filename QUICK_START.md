# Quick Start Guide - Kubernetes Cluster với Calico

## Tổng quan
Hướng dẫn nhanh để cài đặt Kubernetes cluster với Calico networking trên 2 node.

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

## Yêu cầu hệ thống
- **OS**: Ubuntu 20.04+ hoặc CentOS 8+
- **RAM**: Tối thiểu 2GB cho mỗi node
- **CPU**: Tối thiểu 2 cores cho mỗi node
- **Disk**: Tối thiểu 20GB cho mỗi node
- **Network**: Kết nối giữa các node

## Bước 1: Chuẩn bị Worker Node

### 1.1 SSH vào worker node
```bash
ssh phuc@192.168.56.102
```

### 1.2 Chạy setup script
```bash
# Copy script từ master node
scp -r phuc@192.168.56.101:~/k8s-cluster-setup ./

# Chạy setup script
cd k8s-cluster-setup
sudo ./scripts/setup-worker.sh
```

## Bước 2: Cài đặt trên Master Node

### 2.1 Chạy script cài đặt chính
```bash
# Trên master node (192.168.56.101)
cd ~/k8s-cluster-setup
./install.sh
```

**Lưu ý**: Script sẽ tự động xử lý vấn đề Python externally-managed-environment trên Ubuntu 24.04+ bằng cách tạo virtual environment tại `/opt/kubespray-venv`.

### 2.2 Hoặc chạy từng bước
```bash
# Pre-installation
sudo ./scripts/pre-install.sh

# Kubespray installation
./scripts/install-kubespray.sh

# Post-installation
./scripts/post-install.sh
```

## Bước 3: Kiểm tra cài đặt

### 3.1 Kiểm tra cluster status
```bash
kubectl cluster-info
kubectl get nodes -o wide
```

### 3.2 Kiểm tra pods
```bash
kubectl get pods -A
```

### 3.3 Kiểm tra Calico
```bash
kubectl get pods -n kube-system -l k8s-app=calico-node
kubectl get ippool -o yaml
```

## Bước 4: Test cluster

### 4.1 Deploy test application
```bash
# Deploy nginx
kubectl run nginx --image=nginx --port=80

# Expose service
kubectl expose pod nginx --type=LoadBalancer --port=80

# Kiểm tra service
kubectl get svc nginx
```

### 4.2 Test network connectivity
```bash
# Test DNS
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default

# Test external connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -qO- http://google.com
```

## Cấu hình mạng

### Pod Network
- **CIDR**: 10.233.64.0/18
- **Block Size**: 26 (64 IPs per node)
- **IPIP Mode**: CrossSubnet
- **NAT**: Enabled

### Service Network
- **CIDR**: 10.233.0.0/18
- **DNS**: 10.233.0.10

### Load Balancer IPs
- **Range**: 192.168.56.200-192.168.56.250

## Các lệnh hữu ích

### Cluster Management
```bash
# Xem thông tin cluster
kubectl cluster-info

# Xem danh sách nodes
kubectl get nodes -o wide

# Xem tất cả pods
kubectl get pods -A

# Xem tất cả services
kubectl get svc -A
```

### Network Management
```bash
# Xem Calico IP pools
kubectl get ippool -o yaml

# Xem BGP peers
kubectl get bgppeers -o yaml

# Xem network policies
kubectl get networkpolicies -A
```

### Troubleshooting
```bash
# Xem logs của pod
kubectl logs <pod-name> -n <namespace>

# Xem events
kubectl get events --sort-by='.lastTimestamp'

# Xem node conditions
kubectl describe node <node-name>
```

## Monitoring và Logging

### Resource Usage
```bash
# Xem resource usage của nodes
kubectl top nodes

# Xem resource usage của pods
kubectl top pods -A
```

### Logs
```bash
# Xem system logs
sudo journalctl -u kubelet -f

# Xem containerd logs
sudo journalctl -u containerd -f
```

## Backup và Recovery

### Backup etcd
```bash
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/ssl/etcd/ssl/ca.pem \
  --cert=/etc/ssl/etcd/ssl/admin-master.pem \
  --key=/etc/ssl/etcd/ssl/admin-master-key.pem \
  snapshot save /backup/etcd-snapshot-$(date +%Y%m%d_%H%M%S).db
```

### Backup cluster resources
```bash
kubectl get all --all-namespaces -o yaml > /backup/k8s-resources-$(date +%Y%m%d_%H%M%S).yaml
```

## Troubleshooting

### Common Issues
1. **Node Not Ready**: Kiểm tra kubelet service và logs
2. **Pod Scheduling Failed**: Kiểm tra node resources và taints
3. **Network Issues**: Kiểm tra Calico pods và IP pools
4. **Image Pull Errors**: Kiểm tra registry connectivity

### Useful Commands
```bash
# Reset cluster (nếu cần)
ansible-playbook -i inventory/mycluster/hosts.yml --become --become-user=root reset.yml

# Reinstall cluster
ansible-playbook -i inventory/mycluster/hosts.yml --become --become-user=root cluster.yml
```

## Tài liệu tham khảo
- `docs/installation.md` - Hướng dẫn cài đặt chi tiết
- `docs/configuration.md` - Cấu hình chi tiết
- `docs/troubleshooting.md` - Xử lý sự cố

## Liên hệ
DevOps Engineer - Kubernetes Cluster Setup 