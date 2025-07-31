#!/bin/bash

# Kubernetes Cluster Pre-Installation Script
# Chuẩn bị hệ thống trước khi cài đặt Kubernetes với Kubespray

set -e

echo "=== Kubernetes Cluster Pre-Installation Script ==="
echo "Chuẩn bị hệ thống cho việc cài đặt Kubernetes..."

# Kiểm tra quyền sudo
if [ "$EUID" -ne 0 ]; then
    echo "Script này cần chạy với quyền sudo"
    exit 1
fi

# Cập nhật hệ thống
echo "1. Cập nhật hệ thống..."
apt update && apt upgrade -y

# Cài đặt các package cần thiết
echo "2. Cài đặt các package cần thiết..."
apt install -y \
    python3 \
    python3-pip \
    git \
    curl \
    wget \
    vim \
    htop \
    net-tools \
    bridge-utils \
    iptables \
    ipset \
    conntrack \
    socat \
    ebtables \
    ethtool \
    ipvsadm \
    nfs-common \
    rsync

# Tắt swap
echo "3. Tắt swap..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Cấu hình kernel parameters
echo "4. Cấu hình kernel parameters..."
cat >> /etc/sysctl.conf << EOF

# Kubernetes kernel parameters
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv6.conf.all.forwarding = 1
EOF

sysctl --system

# Tắt firewall (cho môi trường lab)
echo "5. Tắt firewall..."
ufw disable

# Cấu hình SSH key authentication
echo "6. Cấu hình SSH..."
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Tạo SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
fi

# Cấu hình hosts file
echo "7. Cấu hình hosts file..."
cat >> /etc/hosts << EOF

# Kubernetes Cluster
192.168.56.101 master
192.168.56.102 worker
EOF

# Tạo thư mục cho Kubernetes
echo "8. Tạo thư mục cho Kubernetes..."
mkdir -p /opt/kubernetes
mkdir -p /var/lib/etcd
mkdir -p /var/lib/kubelet

# Cấu hình timezone
echo "9. Cấu hình timezone..."
timedatectl set-timezone Asia/Ho_Chi_Minh

# Cài đặt Ansible
echo "10. Cài đặt Ansible..."
# Kiểm tra xem có cần tạo virtual environment không
if pip3 install --dry-run ansible 2>&1 | grep -q "externally-managed"; then
    echo "Phát hiện externally-managed environment, tạo virtual environment..."
    # Cài đặt python3-venv nếu chưa có
    if ! dpkg -l | grep -q python3-venv; then
        echo "Cài đặt python3-venv..."
        apt install -y python3-venv python3-full
    fi
    
    # Tạo virtual environment
    if [ ! -d "/opt/kubespray-venv" ]; then
        python3 -m venv /opt/kubespray-venv
        chown -R $SUDO_USER:$SUDO_USER /opt/kubespray-venv
    fi
    
    source /opt/kubespray-venv/bin/activate
    pip install --upgrade pip
    pip install ansible
    echo "Virtual environment đã được tạo tại /opt/kubespray-venv"
    echo "Để sử dụng: source /opt/kubespray-venv/bin/activate"
else
    pip3 install ansible
fi

# Kiểm tra kết nối mạng
echo "11. Kiểm tra kết nối mạng..."
echo "Kiểm tra kết nối đến worker node..."
ping -c 3 192.168.56.102

echo "=== Pre-installation hoàn thành ==="
echo "Hệ thống đã sẵn sàng cho việc cài đặt Kubernetes!"
echo ""
echo "Các bước tiếp theo:"
echo "1. Chạy script cài đặt Kubespray"
echo "2. Cấu hình Calico networking"
echo "3. Kiểm tra cluster" 