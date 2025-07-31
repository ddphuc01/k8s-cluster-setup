#!/bin/bash

# Install NGINX Ingress Controller Script
# Cài đặt NGINX Ingress Controller cho Kubernetes cluster

set -e

echo "=== Install NGINX Ingress Controller Script ==="
echo "Cài đặt NGINX Ingress Controller..."

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

# Cài đặt NGINX Ingress Controller
echo "2. Cài đặt NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml

# Đợi Ingress Controller sẵn sàng
echo "3. Đợi NGINX Ingress Controller sẵn sàng..."
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=300s

# Kiểm tra trạng thái
echo "4. Kiểm tra trạng thái Ingress Controller..."
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Hiển thị thông tin
echo ""
echo "=== NGINX Ingress Controller Installation Complete ==="
echo "✅ NGINX Ingress Controller đã được cài đặt thành công!"
echo ""
echo "📋 Thông tin:"
echo "   Namespace: ingress-nginx"
echo "   Service: ingress-nginx-controller"
echo ""
echo "🔧 Các lệnh hữu ích:"
echo "   # Kiểm tra trạng thái"
echo "   kubectl get pods -n ingress-nginx"
echo ""
echo "   # Xem logs"
echo "   kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller"
echo ""
echo "   # Xem service"
echo "   kubectl get svc -n ingress-nginx"
echo ""
echo "   # Uninstall (nếu cần)"
echo "   kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml"
echo ""

echo "🎉 NGINX Ingress Controller đã sẵn sàng!" 