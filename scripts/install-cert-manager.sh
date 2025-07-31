#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Install cert-manager Script ===${NC}"
echo "Cài đặt cert-manager..."

# 1. Kiểm tra cluster status
echo "1. Kiểm tra cluster status..."
kubectl get nodes

# 2. Xóa cert-manager CRDs nếu tồn tại
echo "2. Dọn dẹp cert-manager CRDs cũ..."
kubectl delete crd certificaterequests.cert-manager.io certificates.cert-manager.io challenges.acme.cert-manager.io clusterissuers.cert-manager.io issuers.cert-manager.io orders.acme.cert-manager.io 2>/dev/null || true

# 3. Đợi một chút để đảm bảo CRDs được xóa hoàn toàn
echo "3. Đợi CRDs được xóa hoàn toàn..."
sleep 10

# 4. Cài đặt cert-manager bằng kubectl
echo "4. Cài đặt cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml

# 5. Đợi cert-manager sẵn sàng
echo "5. Đợi cert-manager sẵn sàng..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s

# 6. Kiểm tra trạng thái
echo "6. Kiểm tra trạng thái cert-manager..."
kubectl get pods -n cert-manager
kubectl get crd | grep cert-manager

echo -e "${GREEN}=== cert-manager Installation Complete ===${NC}"
echo -e "${GREEN}✅ cert-manager đã được cài đặt thành công!${NC}"
echo ""
echo -e "${BLUE}📋 Thông tin:${NC}"
echo "   Namespace: cert-manager"
echo "   Version: v1.13.3"
echo ""
echo -e "${BLUE}🔧 Các lệnh hữu ích:${NC}"
echo "   # Kiểm tra trạng thái"
echo "   kubectl get pods -n cert-manager"
echo ""
echo "   # Xem logs"
echo "   kubectl logs -n cert-manager -l app.kubernetes.io/component=controller"
echo ""
echo "   # Xem CRDs"
echo "   kubectl get crd | grep cert-manager"
echo ""
echo "   # Uninstall (nếu cần)"
echo "   kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml"
echo ""
echo -e "${GREEN}🎉 cert-manager đã sẵn sàng!${NC}" 