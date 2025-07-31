#!/bin/bash

echo "=========================================="
echo "  Kubernetes Monitoring Stack Status"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo ""
print_status "1. Kiểm tra trạng thái Pods..."
echo "📦 Pods trong namespace monitoring:"
kubectl get pods -n monitoring

echo ""
print_status "2. Kiểm tra Services..."
echo "🌐 Services trong namespace monitoring:"
kubectl get svc -n monitoring

echo ""
print_status "3. Kiểm tra Ingress..."
echo "🔗 Ingress trong namespace monitoring:"
kubectl get ingress -n monitoring

echo ""
print_status "4. Kiểm tra Helm Releases..."
echo "📋 Helm releases trong namespace monitoring:"
helm list -n monitoring

echo ""
print_status "5. Kiểm tra StorageClass..."
echo "💾 StorageClass:"
kubectl get storageclass

echo ""
print_status "6. Test kết nối các dịch vụ..."

# Test Grafana
echo "🌐 Testing Grafana..."
if curl -s -I -H "Host: grafana.local" http://192.168.56.101:30098 | grep -q "HTTP"; then
    print_success "Grafana: OK"
else
    print_error "Grafana: FAILED"
fi

# Test Prometheus
echo "📊 Testing Prometheus..."
if curl -s -I -H "Host: prometheus.local" http://192.168.56.101:32702 | grep -q "HTTP"; then
    print_success "Prometheus: OK"
else
    print_error "Prometheus: FAILED"
fi

# Test Alertmanager
echo "🚨 Testing Alertmanager..."
if curl -s -I -H "Host: alertmanager.local" http://192.168.56.101:32702 | grep -q "HTTP"; then
    print_success "Alertmanager: OK"
else
    print_error "Alertmanager: FAILED"
fi

# Test MinIO
echo "📦 Testing MinIO..."
if curl -s -I http://192.168.56.201:9000 | grep -q "HTTP"; then
    print_success "MinIO: OK"
else
    print_error "MinIO: FAILED"
fi

echo ""
print_status "7. Thông tin truy cập:"
echo "=========================================="
echo "🌐 Grafana: http://grafana.local (admin/admin123)"
echo "📊 Prometheus: http://prometheus.local"
echo "🚨 Alertmanager: http://alertmanager.local"
echo "📦 MinIO: http://192.168.56.201:9000 (minioadmin/minioadmin123)"
echo "📦 MinIO Console: http://minio-console.local:9001"
echo ""
echo "🔧 Các lệnh hữu ích:"
echo "   # Kiểm tra logs Grafana"
echo "   kubectl logs -n monitoring -l app.kubernetes.io/name=grafana"
echo ""
echo "   # Kiểm tra logs Prometheus"
echo "   kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus"
echo ""
echo "   # Kiểm tra logs Alertmanager"
echo "   kubectl logs -n monitoring -l app.kubernetes.io/name=alertmanager"
echo ""
echo "   # Port forward Grafana (nếu cần)"
echo "   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo ""
echo "🎉 Monitoring stack đã sẵn sàng!"
echo "==========================================" 