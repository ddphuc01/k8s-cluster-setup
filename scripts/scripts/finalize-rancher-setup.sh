#!/bin/bash

echo "=========================================="
echo "  Rancher Setup Finalization Script"
echo "=========================================="

echo ""
echo "[INFO] Kiểm tra trạng thái Rancher..."

# Kiểm tra pods
echo "📦 Pods trong cattle-system:"
kubectl get pods -n cattle-system

echo ""
echo "🌐 Services trong cattle-system:"
kubectl get svc -n cattle-system

echo ""
echo "🔗 Ingress configuration:"
kubectl get ingress rancher -n cattle-system

echo ""
echo "🔧 NGINX Ingress Controller:"
kubectl get svc -n ingress-nginx

echo ""
echo "📋 Thông tin truy cập Rancher:"
echo "=========================================="
echo "🌐 URL: https://rancher.local:31499"
echo "🏠 IP: 192.168.56.101"
echo "🔑 Port: 31499 (HTTPS)"
echo ""
echo "📝 Để truy cập từ máy khác, thêm vào /etc/hosts:"
echo "   192.168.56.101 rancher.local"
echo ""
echo "🔧 Các lệnh hữu ích:"
echo "   # Kiểm tra logs Rancher"
echo "   kubectl logs -n cattle-system -l app=rancher"
echo ""
echo "   # Kiểm tra logs NGINX Ingress"
echo "   kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller"
echo ""
echo "   # Xem certificate"
echo "   kubectl get certificate -n cattle-system"
echo ""
echo "   # Test kết nối"
echo "   curl -I -k https://rancher.local:31499"
echo ""
echo "🎉 Rancher đã sẵn sàng sử dụng!"
echo "==========================================" 