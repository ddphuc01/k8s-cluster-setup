#!/bin/bash

# Install MetalLB Script
# Cài đặt MetalLB Load Balancer cho Kubernetes cluster

set -e

echo "=== Install MetalLB Script ==="
echo "Cài đặt MetalLB Load Balancer..."

# Kiểm tra kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl không được tìm thấy. Vui lòng cài đặt kubectl trước."
    exit 1
fi

# Kiểm tra cluster
echo "1. Kiểm tra cluster status..."
kubectl get nodes
if [ $? -ne 0 ]; then
    echo "❌ Không thể kết nối đến Kubernetes cluster"
    exit 1
fi

# Cài đặt MetalLB
echo "2. Cài đặt MetalLB..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

# Đợi MetalLB sẵn sàng
echo "3. Đợi MetalLB sẵn sàng..."
kubectl wait --namespace metallb-system \
    --for=condition=ready pod \
    --selector=app=metallb \
    --timeout=300s

# Cấu hình IP Address Pool
echo "4. Cấu hình IP Address Pool..."
kubectl apply -f - <<EOF
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

# Kiểm tra trạng thái
echo "5. Kiểm tra trạng thái MetalLB..."
kubectl get pods -n metallb-system
kubectl get ipaddresspools -n metallb-system
kubectl get l2advertisements -n metallb-system

# Hiển thị thông tin
echo ""
echo "=== MetalLB Installation Complete ==="
echo "✅ MetalLB đã được cài đặt thành công!"
echo ""
echo "📋 Thông tin:"
echo "   Namespace: metallb-system"
echo "   IP Pool: 192.168.56.200-192.168.56.250"
echo ""
echo "🔧 Các lệnh hữu ích:"
echo "   # Kiểm tra trạng thái"
echo "   kubectl get pods -n metallb-system"
echo ""
echo "   # Xem IP pools"
echo "   kubectl get ipaddresspools -n metallb-system"
echo ""
echo "   # Xem L2 advertisements"
echo "   kubectl get l2advertisements -n metallb-system"
echo ""
echo "   # Test LoadBalancer service"
echo "   kubectl run nginx --image=nginx --port=80"
echo "   kubectl expose pod nginx --port=80 --type=LoadBalancer"
echo ""
echo "   # Uninstall (nếu cần)"
echo "   kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml"
echo ""

echo "🎉 MetalLB đã sẵn sàng!" 