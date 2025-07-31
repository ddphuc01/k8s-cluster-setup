#!/bin/bash

# Cleanup Cert-Manager Script
# Xóa hoàn toàn cert-manager và CRDs

set -e

echo "=== Cleanup Cert-Manager Script ==="
echo "Xóa hoàn toàn cert-manager và CRDs..."

# Kiểm tra kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl không được tìm thấy. Vui lòng cài đặt kubectl trước."
    exit 1
fi

echo "1. Xóa namespace cert-manager..."
kubectl delete namespace cert-manager --ignore-not-found=true

echo "2. Đợi namespace được xóa..."
kubectl wait --for=delete namespace/cert-manager --timeout=60s 2>/dev/null || echo "Namespace đã được xóa"

echo "3. Xóa cert-manager CRDs..."
kubectl delete crd certificaterequests.cert-manager.io --ignore-not-found=true
kubectl delete crd certificates.cert-manager.io --ignore-not-found=true
kubectl delete crd challenges.acme.cert-manager.io --ignore-not-found=true
kubectl delete crd clusterissuers.cert-manager.io --ignore-not-found=true
kubectl delete crd issuers.cert-manager.io --ignore-not-found=true
kubectl delete crd orders.acme.cert-manager.io --ignore-not-found=true

echo "4. Xóa cert-manager webhook configurations..."
kubectl delete validatingwebhookconfigurations cert-manager-webhook --ignore-not-found=true
kubectl delete mutatingwebhookconfigurations cert-manager-webhook --ignore-not-found=true

echo "5. Xóa cert-manager cluster roles và bindings..."
kubectl delete clusterrole cert-manager-controller --ignore-not-found=true
kubectl delete clusterrole cert-manager-cainjector --ignore-not-found=true
kubectl delete clusterrole cert-manager-webhook --ignore-not-found=true
kubectl delete clusterrolebinding cert-manager-controller --ignore-not-found=true
kubectl delete clusterrolebinding cert-manager-cainjector --ignore-not-found=true
kubectl delete clusterrolebinding cert-manager-webhook --ignore-not-found=true

echo "6. Kiểm tra xem còn resources nào không..."
echo "Checking for remaining cert-manager resources..."
kubectl get crd | grep cert-manager || echo "No cert-manager CRDs found"
kubectl get validatingwebhookconfigurations | grep cert-manager || echo "No cert-manager webhooks found"
kubectl get clusterrole | grep cert-manager || echo "No cert-manager cluster roles found"

echo ""
echo "=== Cert-Manager Cleanup Complete ==="
echo "✅ Cert-manager đã được xóa hoàn toàn!"
echo ""
echo "🔧 Bây giờ bạn có thể cài đặt lại cert-manager:"
echo "   ./scripts/install-cert-manager.sh"
echo ""
echo "�� Cleanup hoàn tất!" 