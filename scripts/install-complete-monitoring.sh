#!/bin/bash

echo "=========================================="
echo "  Complete Kubernetes Monitoring Stack"
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

# Check prerequisites
print_status "Kiểm tra prerequisites..."

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    print_error "helm is not installed"
    exit 1
fi

print_success "Prerequisites OK"

# Step 1: Add Helm repositories
print_status "Bước 1: Thêm Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add minio https://charts.min.io/
helm repo update
print_success "Helm repositories added"

# Step 2: Create namespace
print_status "Bước 2: Tạo namespace monitoring..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
print_success "Namespace created"

# Step 3: Install StorageClass
print_status "Bước 3: Cài đặt local-path-provisioner..."
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
sleep 10
print_success "StorageClass installed"

# Step 4: Install MinIO
print_status "Bước 4: Cài đặt MinIO..."
helm install minio minio/minio \
  --namespace monitoring \
  --set auth.rootUser=minioadmin \
  --set auth.rootPassword=minioadmin123 \
  --set mode=standalone \
  --set persistence.size=5Gi \
  --set persistence.storageClass=local-path \
  --set resources.requests.memory=256Mi \
  --set resources.requests.cpu=100m \
  --set resources.limits.memory=512Mi \
  --set resources.limits.cpu=200m \
  --set service.type=LoadBalancer \
  --wait --timeout=5m
print_success "MinIO installed"

# Step 5: Install Prometheus Stack
print_status "Bước 5: Cài đặt Prometheus Stack..."
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.enabled=true \
  --set grafana.adminPassword=admin123 \
  --set grafana.service.type=LoadBalancer \
  --set grafana.ingress.enabled=true \
  --set grafana.ingress.hosts[0]=grafana.local \
  --set grafana.ingress.ingressClassName=nginx \
  --set alertmanager.enabled=true \
  --set alertmanager.alertmanagerSpec.service.type=LoadBalancer \
  --wait --timeout=10m
print_success "Prometheus Stack installed"

# Step 6: Install Promtail
print_status "Bước 6: Cài đặt Promtail..."
helm install promtail grafana/promtail \
  --namespace monitoring \
  --set loki.serviceName=loki \
  --set loki.servicePort=3100 \
  --wait --timeout=5m
print_success "Promtail installed"

# Step 7: Apply Ingress configurations
print_status "Bước 7: Cấu hình Ingress..."
kubectl apply -f manifests/monitoring/prometheus-ingress.yaml
kubectl apply -f manifests/monitoring/alertmanager-ingress.yaml
print_success "Ingress configured"

# Step 8: Apply monitoring configurations
print_status "Bước 8: Cấu hình monitoring..."
kubectl apply -f manifests/monitoring/prometheus-rules.yaml
kubectl apply -f manifests/monitoring/alertmanager-config.yaml
kubectl apply -f manifests/monitoring/grafana-dashboards.yaml
print_success "Monitoring configurations applied"

# Step 9: Update /etc/hosts
print_status "Bước 9: Cập nhật /etc/hosts..."
echo "192.168.56.101 prometheus.local alertmanager.local minio.local minio-console.local" | sudo tee -a /etc/hosts
print_success "/etc/hosts updated"

# Step 10: Wait for all pods to be ready
print_status "Bước 10: Đợi tất cả pods sẵn sàng..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod -l app=minio -n monitoring --timeout=300s
print_success "All pods ready"

# Step 11: Final status check
print_status "Bước 11: Kiểm tra trạng thái cuối cùng..."
./scripts/check-monitoring-stack.sh

print_success "=========================================="
print_success "  Monitoring Stack Installation Complete!"
print_success "=========================================="

echo ""
echo "📋 Thông tin truy cập:"
echo "=========================================="
echo "🌐 Grafana: http://grafana.local (admin/admin123)"
echo "📊 Prometheus: http://prometheus.local"
echo "🚨 Alertmanager: http://alertmanager.local"
echo "📦 MinIO: http://192.168.56.201:9000 (minioadmin/minioadmin123)"
echo "📦 MinIO Console: http://minio-console.local:9001"
echo ""
echo "🔧 Các lệnh hữu ích:"
echo "   # Kiểm tra trạng thái"
echo "   ./scripts/check-monitoring-stack.sh"
echo ""
echo "   # Xem logs"
echo "   kubectl logs -n monitoring -l app.kubernetes.io/name=grafana"
echo "   kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus"
echo ""
echo "   # Port forward"
echo "   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo ""
echo "🎉 Monitoring stack đã sẵn sàng!"
echo "==========================================" 