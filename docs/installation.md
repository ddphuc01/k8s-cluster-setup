# Hướng dẫn cài đặt Kubernetes Cluster với Calico

## Tổng quan
Tài liệu này hướng dẫn chi tiết cách cài đặt Kubernetes cluster sử dụng Kubespray với Calico CNI trên 2 node.

## Yêu cầu hệ thống

### Phần cứng tối thiểu
- **CPU**: 2 cores cho mỗi node
- **RAM**: 2GB cho mỗi node
- **Disk**: 20GB cho mỗi node
- **Network**: 1Gbps Ethernet

### Phần mềm
- Ubuntu 20.04+ hoặc CentOS 8+
- Python 3.8+
- Ansible 2.12+
- Git

### Network
- Master Node: 192.168.56.101
- Worker Node: 192.168.56.102
- Pod Network: 10.233.64.0/18
- Service Network: 10.233.0.0/18

## Bước 1: Chuẩn bị hệ thống

### 1.1 Cập nhật hệ thống
```bash
sudo apt update && sudo apt upgrade -y
```

### 1.2 Cài đặt dependencies
```bash
sudo apt install -y python3 python3-pip python3-venv python3-full git curl wget vim htop \
    net-tools bridge-utils iptables ipset conntrack socat \
    ebtables ethtool ipvsadm nfs-common rsync
```

**Lưu ý**: Trên Ubuntu 24.04+, Python sử dụng externally-managed environment. Script sẽ tự động tạo virtual environment để tránh xung đột.

### 1.3 Tắt swap
```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

### 1.4 Cấu hình kernel parameters
```bash
cat >> /etc/sysctl.conf << EOF

# Kubernetes kernel parameters
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv6.conf.all.forwarding = 1
EOF

sudo sysctl --system
```

### 1.5 Cấu hình SSH
```bash
# Tạo SSH key nếu chưa có
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Copy key đến worker node
ssh-copy-id phuc@192.168.56.102
```

### 1.6 Cấu hình hosts file
```bash
sudo tee -a /etc/hosts << EOF

# Kubernetes Cluster
192.168.56.101 master
192.168.56.102 worker
EOF
```

## Bước 2: Cài đặt Kubespray

### 2.1 Clone Kubespray
```bash
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
git checkout v2.24.0
```

### 2.2 Cài đặt dependencies
```bash
pip3 install -r requirements.txt
```

### 2.3 Copy inventory
```bash
cp -rfp inventory/sample inventory/mycluster
```

### 2.4 Cấu hình inventory
Tạo file `inventory/mycluster/hosts.yml`:
```yaml
all:
  hosts:
    master:
      ansible_host: 192.168.56.101
      ansible_user: phuc
      ansible_ssh_private_key_file: ~/.ssh/id_rsa
      ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
      ip: 192.168.56.101
      access_ip: 192.168.56.101
    worker:
      ansible_host: 192.168.56.102
      ansible_user: phuc
      ansible_ssh_private_key_file: ~/.ssh/id_rsa
      ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
      ip: 192.168.56.102
      access_ip: 192.168.56.102
  children:
    kube_control_plane:
      hosts:
        master:
    kube_node:
      hosts:
        master:
        worker:
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

### 2.5 Cấu hình Calico
Tạo file `inventory/mycluster/group_vars/k8s_cluster.yml`:
```yaml
# Kubernetes Cluster Configuration
kube_version: v1.28.5
container_manager: containerd
dns_mode: coredns
helm_enabled: true
metrics_server_enabled: true

# Calico CNI Configuration
kube_network_plugin: calico
calico_version: v3.26.1
calico_typha_enabled: false
calico_typha_replicas: 0

# Network Configuration
kube_service_addresses: 10.233.0.0/18
kube_pods_subnet: 10.233.64.0/18
kube_network_node_prefix: 24

# Calico IP Pool Configuration
calico_ip_auto_method: "kubernetes-internal-ip"
calico_ipv4pool_cidr: "10.233.64.0/18"
calico_ipv4pool_ipip: "CrossSubnet"
calico_ipv4pool_vxlan: "Never"

# Security Configuration
podsecuritypolicy_enabled: false
kubernetes_audit: false

# Addon Configuration
dashboard_enabled: false
helm_enabled: true
registry_enabled: false

# Container Runtime Configuration
container_manager: containerd
containerd_use_systemd_cgroup: true

# Node Configuration
kubelet_cgroup_driver: systemd
kubelet_eviction_hard: "memory.available<100Mi,nodefs.available<10%"
kubelet_eviction_soft: "memory.available<200Mi,nodefs.available<15%"
kubelet_eviction_soft_grace_period: "memory.available=30s,nodefs.available=30s"
```

### 2.6 Chạy Ansible playbook
```bash
ansible-playbook -i inventory/mycluster/hosts.yml \
    --become \
    --become-user=root \
    cluster.yml
```

## Bước 3: Cấu hình sau cài đặt

### 3.1 Copy kubeconfig
```bash
mkdir -p ~/.kube
cp inventory/mycluster/artifacts/admin.conf ~/.kube/config
chmod 600 ~/.kube/config
```

### 3.2 Kiểm tra cluster
```bash
kubectl get nodes
kubectl get pods -A
```

### 3.3 Cấu hình Calico IP Pool
```bash
cat << EOF | kubectl apply -f -
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: default-ipv4-ippool
spec:
  blockSize: 26
  cidr: 10.233.64.0/18
  ipipMode: CrossSubnet
  natOutgoing: true
  nodeSelector: all()
  vxlanMode: Never
EOF
```

### 3.4 Cài đặt MetalLB
```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

cat << EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.56.200-192.168.56.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
EOF
```

## Bước 4: Kiểm tra và test

### 4.1 Kiểm tra cluster status
```bash
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -A
```

### 4.2 Test deployment
```bash
# Deploy nginx
kubectl run nginx --image=nginx --port=80

# Expose service
kubectl expose pod nginx --type=LoadBalancer --port=80

# Kiểm tra service
kubectl get svc nginx
```

### 4.3 Test network connectivity
```bash
# Test pod-to-pod communication
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default

# Test external connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -qO- http://google.com
```

## Troubleshooting

### Kiểm tra logs
```bash
# Kiểm tra kubelet logs
sudo journalctl -u kubelet -f

# Kiểm tra containerd logs
sudo journalctl -u containerd -f

# Kiểm tra calico logs
kubectl logs -n kube-system -l k8s-app=calico-node
```

### Kiểm tra network
```bash
# Kiểm tra calico status
kubectl get pods -n kube-system -l k8s-app=calico-node

# Kiểm tra calico IP pools
kubectl get ippool -o yaml

# Kiểm tra BGP peers
kubectl get bgppeers -o yaml
```

### Reset cluster (nếu cần)
```bash
ansible-playbook -i inventory/mycluster/hosts.yml \
    --become \
    --become-user=root \
    reset.yml
```

## Kết luận
Sau khi hoàn thành các bước trên, bạn sẽ có một Kubernetes cluster hoạt động với:
- Calico networking với IPIP mode
- MetalLB load balancer
- NGINX Ingress Controller
- RBAC và Network Policies
- Monitoring và logging namespaces

Cluster sẵn sàng để deploy các ứng dụng production. 