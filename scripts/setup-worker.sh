#!/bin/bash

# Worker Node Setup Script
# Script để cài đặt worker node cho Kubernetes cluster

set -e

echo "=== Worker Node Setup Script ==="
echo "Cài đặt worker node cho Kubernetes cluster..."

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

# Cấu hình hosts file
echo "6. Cấu hình hosts file..."
cat >> /etc/hosts << EOF

# Kubernetes Cluster
192.168.56.101 master
192.168.56.102 worker
EOF

# Tạo thư mục cho Kubernetes
echo "7. Tạo thư mục cho Kubernetes..."
mkdir -p /opt/kubernetes
mkdir -p /var/lib/kubelet

# Cấu hình timezone
echo "8. Cấu hình timezone..."
timedatectl set-timezone Asia/Ho_Chi_Minh

# Cấu hình SSH để cho phép master node truy cập
echo "9. Cấu hình SSH..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Tạo authorized_keys nếu chưa có
if [ ! -f ~/.ssh/authorized_keys ]; then
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
fi

echo "=== Worker node setup hoàn thành ==="
echo "Worker node đã sẵn sàng để join vào cluster!"
echo ""
echo "Lưu ý:"
echo "1. Đảm bảo master node có thể SSH vào worker node"
echo "2. Chạy script cài đặt trên master node"
echo "3. Worker node sẽ được tự động join vào cluster" 