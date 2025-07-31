#!/bin/bash

# Kubernetes Cluster Installation Script với Kubespray
# Cài đặt Kubernetes cluster với Calico networking

set -e

echo "=== Kubernetes Cluster Installation với Kubespray ==="
echo "Bắt đầu cài đặt Kubernetes cluster..."

# Kiểm tra thư mục hiện tại
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Kiểm tra inventory file
if [ ! -f "inventory/hosts.yml" ]; then
    echo "Lỗi: Không tìm thấy file inventory/hosts.yml"
    exit 1
fi

# Clone Kubespray repository
echo "1. Clone Kubespray repository..."
if [ ! -d "kubespray" ]; then
    git clone https://github.com/kubernetes-sigs/kubespray.git
fi

cd kubespray

# Checkout stable version
echo "2. Checkout stable version..."
git checkout v2.24.0

# Cài đặt dependencies
echo "3. Cài đặt dependencies..."
# Kiểm tra và sử dụng virtual environment nếu có
if [ -d "/opt/kubespray-venv" ]; then
    echo "Sử dụng virtual environment..."
    source /opt/kubespray-venv/bin/activate
    pip install -r requirements.txt
else
    # Thử cài đặt trực tiếp, nếu lỗi thì tạo virtual environment
    if ! pip3 install -r requirements.txt 2>/dev/null; then
        echo "Tạo virtual environment cho Kubespray..."
        python3 -m venv kubespray-venv
        source kubespray-venv/bin/activate
        pip install --upgrade pip
        pip install -r requirements.txt
    fi
fi

# Copy inventory
echo "4. Copy inventory..."
cp -rfp inventory/sample inventory/mycluster

# Copy custom inventory
echo "5. Copy custom inventory..."
cp ../inventory/hosts.yml inventory/mycluster/
cp ../inventory/group_vars/k8s_cluster.yml inventory/mycluster/group_vars/k8s_cluster.yml

# Cấu hình Calico
echo "6. Cấu hình Calico networking..."
cat > inventory/mycluster/group_vars/k8s_cluster.yml << EOF
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
EOF

# Chạy Ansible playbook
echo "7. Bắt đầu cài đặt Kubernetes cluster..."
echo "Quá trình này có thể mất 15-30 phút..."

# Sử dụng virtual environment nếu có
if [ -d "/opt/kubespray-venv" ]; then
    source /opt/kubespray-venv/bin/activate
    ansible-playbook -i inventory/mycluster/hosts.yml \
        --become \
        --become-user=root \
        cluster.yml
elif [ -d "kubespray-venv" ]; then
    source kubespray-venv/bin/activate
    ansible-playbook -i inventory/mycluster/hosts.yml \
        --become \
        --become-user=root \
        cluster.yml
else
    ansible-playbook -i inventory/mycluster/hosts.yml \
        --become \
        --become-user=root \
        cluster.yml
fi

# Copy kubeconfig
echo "8. Copy kubeconfig..."
mkdir -p ~/.kube
cp inventory/mycluster/artifacts/admin.conf ~/.kube/config
chmod 600 ~/.kube/config

# Kiểm tra cluster
echo "9. Kiểm tra cluster..."
kubectl get nodes
kubectl get pods -A

echo "=== Cài đặt Kubernetes cluster hoàn thành ==="
echo ""
echo "Cluster đã được cài đặt thành công!"
echo "Master Node: 192.168.56.101"
echo "Worker Node: 192.168.56.102"
echo ""
echo "Các lệnh hữu ích:"
echo "- kubectl get nodes          # Xem danh sách nodes"
echo "- kubectl get pods -A        # Xem tất cả pods"
echo "- kubectl get svc -A         # Xem tất cả services"
echo "- kubectl get pv             # Xem persistent volumes"
echo ""
echo "Để truy cập cluster từ máy khác:"
echo "scp ~/.kube/config user@remote-machine:~/.kube/" 