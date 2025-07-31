#!/bin/bash

# Fix Cert-Manager Script
# Cleanup cert-manager cũ và cài đặt lại đúng cách

set -e

echo "=== Fix Cert-Manager Script ==="
echo "Cleanup cert-manager cũ và cài đặt lại..."

# Kiểm tra kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl không được tìm thấy. Vui lòng cài đặt kubectl trước."
    exit 1
fi

# Kiểm tra helm
if ! command -v helm &> /dev/null; then
    echo "❌ helm không được tìm thấy. Vui lòng cài đặt helm trước."
    exit 1
fi

echo "1. Kiểm tra trạng thái cert-manager hiện tại..."
kubectl get pods -n cert-manager 2>/dev/null || echo "Namespace cert-manager không tồn tại"

echo "2. Cleanup cert-manager cũ..."
# Xóa tất cả resources trong namespace cert-manager
kubectl delete namespace cert-manager --ignore-not-found=true

# Đợi namespace được xóa hoàn toàn
echo "3. Đợi namespace cert-manager được xóa..."
kubectl wait --for=delete namespace/cert-manager --timeout=60s 2>/dev/null || echo "Namespace đã được xóa"

echo "4. Cài đặt lại cert-manager với Helm..."

# Thêm Helm repository
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Cài đặt CRDs
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.crds.yaml

# Cài đặt cert-manager với Helm
helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version v1.13.3 \
    --set installCRDs=true \
    --wait

echo "5. Đợi cert-manager sẵn sàng..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s

echo "6. Kiểm tra trạng thái cert-manager..."
kubectl get pods -n cert-manager

echo ""
echo "=== Cert-Manager Fix Complete ==="
echo "✅ Cert-manager đã được cài đặt lại thành công!"
echo ""
echo "🔧 Các lệnh hữu ích:"
echo "   # Kiểm tra trạng thái"
echo "   kubectl get pods -n cert-manager"
echo ""
echo "   # Xem logs"
echo "   kubectl logs -n cert-manager -l app=cert-manager"
echo ""
echo "   # Test cert-manager"
echo "   kubectl apply -f - <<EOF"
echo "   apiVersion: cert-manager.io/v1"
echo "   kind: ClusterIssuer"
echo "   metadata:"
echo "     name: test-selfsigned"
echo "   spec:"
echo "     selfSigned: {}"
echo "   EOF"
echo ""
echo "🎉 Cert-manager đã sẵn sàng!" 