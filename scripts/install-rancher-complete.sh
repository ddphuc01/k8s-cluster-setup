#!/bin/bash

# Install Rancher Complete Script
# Cài đặt hoàn chỉnh Rancher với tất cả dependencies

set -e

echo "=========================================="
echo "  Rancher Complete Installation Script"
echo "=========================================="
echo ""

# Kiểm tra kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl không được tìm thấy. Vui lòng cài đặt kubectl trước."
    exit 1
fi

# Kiểm tra cluster
echo "[INFO] Kiểm tra cluster status..."
kubectl get nodes
if [ $? -ne 0 ]; then
    echo "❌ Không thể kết nối đến Kubernetes cluster"
    exit 1
fi

echo "[SUCCESS] Cluster đã sẵn sàng"
echo ""

# Bước 1: Cài đặt MetalLB
echo "[INFO] Bước 1: Cài đặt MetalLB Load Balancer..."
./scripts/install-metallb.sh
if [ $? -ne 0 ]; then
    echo "❌ Lỗi cài đặt MetalLB"
    exit 1
fi
echo "[SUCCESS] MetalLB đã được cài đặt"
echo ""

# Bước 2: Cài đặt NGINX Ingress Controller
echo "[INFO] Bước 2: Cài đặt NGINX Ingress Controller..."
./scripts/install-ingress.sh
if [ $? -ne 0 ]; then
    echo "❌ Lỗi cài đặt NGINX Ingress Controller"
    exit 1
fi
echo "[SUCCESS] NGINX Ingress Controller đã được cài đặt"
echo ""

# Bước 3: Cài đặt Rancher
echo "[INFO] Bước 3: Cài đặt Rancher..."
./scripts/install-rancher.sh
if [ $? -ne 0 ]; then
    echo "❌ Lỗi cài đặt Rancher"
    exit 1
fi
echo "[SUCCESS] Rancher đã được cài đặt"
echo ""

# Hiển thị thông tin tổng kết
echo "=========================================="
echo "  Rancher Installation Complete!"
echo "=========================================="
echo ""
echo "✅ Tất cả components đã được cài đặt thành công:"
echo "   - MetalLB Load Balancer"
echo "   - NGINX Ingress Controller"
echo "   - Rancher Management Platform"
echo ""
echo "📋 Thông tin truy cập Rancher:"
echo "   URL: https://rancher.192.168.56.101.nip.io"
echo "   Username: admin"
echo "   Password: admin123"
echo ""
echo "🔧 Các lệnh kiểm tra:"
echo "   # Kiểm tra MetalLB"
echo "   kubectl get pods -n metallb-system"
echo ""
echo "   # Kiểm tra Ingress Controller"
echo "   kubectl get pods -n ingress-nginx"
echo ""
echo "   # Kiểm tra Rancher"
echo "   kubectl get pods -n cattle-system"
echo ""
echo "🌐 Truy cập Rancher UI để quản lý cluster!"
echo ""
echo "🎉 Installation hoàn thành!" 