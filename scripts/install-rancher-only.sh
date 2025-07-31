#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Install Rancher Script ===${NC}"
echo "Cài đặt Rancher trên Kubernetes cluster..."

# 1. Kiểm tra cluster status
echo "1. Kiểm tra cluster status..."
kubectl get nodes

# 2. Kiểm tra Helm
echo "2. Kiểm tra Helm..."
if command -v helm &> /dev/null; then
    echo -e "${GREEN}✅ Helm đã được cài đặt: $(helm version --short)${NC}"
else
    echo -e "${RED}❌ Helm chưa được cài đặt${NC}"
    exit 1
fi

# 3. Thêm Helm repositories
echo "3. Thêm Helm repositories..."
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo add jetstack https://charts.jetstack.io
helm repo update

# 4. Kiểm tra cert-manager
echo "4. Kiểm tra cert-manager..."
if kubectl get pods -n cert-manager &> /dev/null; then
    echo -e "${GREEN}✅ cert-manager đã được cài đặt${NC}"
else
    echo -e "${RED}❌ cert-manager chưa được cài đặt${NC}"
    exit 1
fi

# 5. Cài đặt Rancher
echo "5. Cài đặt Rancher..."
helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --create-namespace \
  --set hostname=rancher.local \
  --set bootstrapPassword=admin123 \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=admin@example.com \
  --set letsEncrypt.ingress.class=nginx \
  --set auditLog.level=2 \
  --set auditLog.maxAge=1 \
  --set auditLog.maxBackup=1 \
  --set auditLog.maxSize=100

# 6. Đợi Rancher sẵn sàng
echo "6. Đợi Rancher sẵn sàng..."
kubectl wait --for=condition=ready pod -l app=rancher -n cattle-system --timeout=600s

# 7. Kiểm tra trạng thái
echo "7. Kiểm tra trạng thái Rancher..."
kubectl get pods -n cattle-system
kubectl get svc -n cattle-system

echo -e "${GREEN}=== Rancher Installation Complete ===${NC}"
echo -e "${GREEN}✅ Rancher đã được cài đặt thành công!${NC}"
echo ""
echo -e "${BLUE}📋 Thông tin:${NC}"
echo "   Namespace: cattle-system"
echo "   Hostname: rancher.local"
echo "   Bootstrap Password: admin123"
echo ""
echo -e "${BLUE}🔧 Các lệnh hữu ích:${NC}"
echo "   # Kiểm tra trạng thái"
echo "   kubectl get pods -n cattle-system"
echo ""
echo "   # Xem logs"
echo "   kubectl logs -n cattle-system -l app=rancher"
echo ""
echo "   # Xem service"
echo "   kubectl get svc -n cattle-system"
echo ""
echo "   # Truy cập Rancher UI"
echo "   # Thêm vào /etc/hosts: 192.168.56.200 rancher.local"
echo "   # Truy cập: https://rancher.local"
echo ""
echo "   # Uninstall (nếu cần)"
echo "   helm uninstall rancher -n cattle-system"
echo ""
echo -e "${GREEN}🎉 Rancher đã sẵn sàng!${NC}" 