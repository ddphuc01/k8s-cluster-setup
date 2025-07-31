#!/bin/bash

# Install Rancher Script
# Cài đặt Rancher trên Kubernetes cluster

set -e

echo "=== Install Rancher Script ==="
echo "Cài đặt Rancher trên Kubernetes cluster..."

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

# Kiểm tra helm
echo "2. Kiểm tra Helm..."
if ! command -v helm &> /dev/null; then
    echo "Cài đặt Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    echo "✅ Helm đã được cài đặt: $(helm version --short)"
fi

# Thêm Helm repositories
echo "3. Thêm Helm repositories..."
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Cài đặt cert-manager (yêu cầu cho Rancher)
echo "4. Cài đặt cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.crds.yaml

helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version v1.13.3 \
    --set installCRDs=true

# Đợi cert-manager sẵn sàng
echo "5. Đợi cert-manager sẵn sàng..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s

# Cài đặt Rancher
echo "6. Cài đặt Rancher..."

# Tạo namespace cho Rancher
kubectl create namespace cattle-system --dry-run=client -o yaml | kubectl apply -f -

# Cài đặt Rancher với hostname
RANCHER_HOSTNAME="rancher.192.168.56.101.nip.io"

helm install rancher rancher-latest/rancher \
    --namespace cattle-system \
    --set hostname=$RANCHER_HOSTNAME \
    --set bootstrapPassword=admin123 \
    --set ingress.tls.source=letsEncrypt \
    --set letsEncrypt.email=admin@example.com \
    --set letsEncrypt.ingress.class=nginx

echo "7. Đợi Rancher sẵn sàng..."
kubectl wait --for=condition=ready pod -l app=rancher -n cattle-system --timeout=600s

# Hiển thị thông tin
echo ""
echo "=== Rancher Installation Complete ==="
echo "✅ Rancher đã được cài đặt thành công!"
echo ""
echo "📋 Thông tin truy cập:"
echo "   URL: https://$RANCHER_HOSTNAME"
echo "   Username: admin"
echo "   Password: admin123"
echo ""
echo "🔧 Các lệnh hữu ích:"
echo "   # Kiểm tra trạng thái Rancher"
echo "   kubectl get pods -n cattle-system"
echo ""
echo "   # Xem logs Rancher"
echo "   kubectl logs -n cattle-system -l app=rancher"
echo ""
echo "   # Uninstall Rancher (nếu cần)"
echo "   helm uninstall rancher -n cattle-system"
echo ""

# Kiểm tra trạng thái
echo "8. Kiểm tra trạng thái Rancher..."
kubectl get pods -n cattle-system
kubectl get ingress -n cattle-system

echo ""
echo "🎉 Rancher đã sẵn sàng sử dụng!" 