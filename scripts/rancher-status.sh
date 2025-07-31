#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Rancher Status & Access Information${NC}"
echo -e "${BLUE}==========================================${NC}"

# 1. Kiểm tra cluster status
echo -e "\n${BLUE}[INFO] Cluster Status:${NC}"
kubectl get nodes

# 2. Kiểm tra MetalLB
echo -e "\n${BLUE}[INFO] MetalLB Status:${NC}"
kubectl get pods -n metallb-system
kubectl get ipaddresspools -n metallb-system

# 3. Kiểm tra NGINX Ingress Controller
echo -e "\n${BLUE}[INFO] NGINX Ingress Controller Status:${NC}"
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# 4. Kiểm tra cert-manager
echo -e "\n${BLUE}[INFO] cert-manager Status:${NC}"
kubectl get pods -n cert-manager

# 5. Kiểm tra Rancher
echo -e "\n${BLUE}[INFO] Rancher Status:${NC}"
kubectl get pods -n cattle-system
kubectl get svc -n cattle-system
kubectl get ingress -n cattle-system

# 6. Lấy thông tin truy cập
echo -e "\n${BLUE}[INFO] Access Information:${NC}"
EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
BOOTSTRAP_PASSWORD=$(kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}')

echo -e "${GREEN}✅ External IP: ${EXTERNAL_IP}${NC}"
echo -e "${GREEN}✅ Rancher URL: https://rancher.local${NC}"
echo -e "${GREEN}✅ Bootstrap Password: ${BOOTSTRAP_PASSWORD}${NC}"

# 7. Kiểm tra kết nối
echo -e "\n${BLUE}[INFO] Testing Connection:${NC}"
if curl -k -s -o /dev/null -w "%{http_code}" https://rancher.local | grep -q "200\|302"; then
    echo -e "${GREEN}✅ Rancher is accessible!${NC}"
else
    echo -e "${YELLOW}⚠️  Rancher might still be initializing...${NC}"
    echo -e "${YELLOW}   Please wait a few more minutes and try again.${NC}"
fi

# 8. Hướng dẫn truy cập
echo -e "\n${BLUE}[INFO] Access Instructions:${NC}"
echo -e "${GREEN}1. Open your browser and go to: https://rancher.local${NC}"
echo -e "${GREEN}2. Accept the SSL certificate warning (self-signed)${NC}"
echo -e "${GREEN}3. Use the bootstrap password: ${BOOTSTRAP_PASSWORD}${NC}"
echo -e "${GREEN}4. Follow the setup wizard to complete Rancher configuration${NC}"

# 9. Troubleshooting commands
echo -e "\n${BLUE}[INFO] Troubleshooting Commands:${NC}"
echo -e "${YELLOW}# Check Rancher logs:${NC}"
echo "kubectl logs -n cattle-system -l app=rancher"
echo -e "${YELLOW}# Check Ingress logs:${NC}"
echo "kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller"
echo -e "${YELLOW}# Check cert-manager logs:${NC}"
echo "kubectl logs -n cert-manager -l app.kubernetes.io/component=controller"

echo -e "\n${GREEN}🎉 Rancher installation completed successfully!${NC}" 