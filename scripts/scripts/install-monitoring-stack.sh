#!/bin/bash

echo "=========================================="
echo "  Kubernetes Monitoring Stack Installation"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    print_error "helm is not installed or not in PATH"
    exit 1
fi

print_status "Kiểm tra cluster status..."
kubectl get nodes

print_status "Bước 1: Thêm Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add loki https://grafana.github.io/loki/charts
helm repo update

print_status "Bước 2: Tạo namespace cho monitoring..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

print_status "Bước 3: Cài đặt Prometheus Stack (Prometheus + Alertmanager)..."
helm install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
    --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
    --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false \
    --set prometheus.prometheusSpec.probeSelectorNilUsesHelmValues=false \
    --set grafana.enabled=true \
    --set grafana.adminPassword=admin123 \
    --set grafana.service.type=LoadBalancer \
    --set grafana.ingress.enabled=true \
    --set grafana.ingress.hosts[0]=grafana.local \
    --set grafana.ingress.ingressClassName=nginx \
    --set alertmanager.enabled=true \
    --set alertmanager.alertmanagerSpec.service.type=LoadBalancer \
    --set alertmanager.alertmanagerSpec.ingress.enabled=true \
    --set alertmanager.alertmanagerSpec.ingress.hosts[0]=alertmanager.local \
    --set alertmanager.alertmanagerSpec.ingress.ingressClassName=nginx \
    --wait --timeout=10m

print_status "Bước 4: Cài đặt Loki (Log aggregation)..."
helm install loki grafana/loki \
    --namespace monitoring \
    --set loki.auth_enabled=false \
    --set loki.commonConfig.replication_factor=1 \
    --set loki.storage.type=filesystem \
    --set loki.storage.filesystem.chunks_directory=/var/loki/chunks \
    --set loki.storage.filesystem.rules_directory=/var/loki/rules \
    --set service.type=LoadBalancer \
    --set ingress.enabled=true \
    --set ingress.hosts[0]=loki.local \
    --set ingress.ingressClassName=nginx \
    --wait --timeout=5m

print_status "Bước 5: Cài đặt Promtail (Log collection)..."
helm install promtail grafana/promtail \
    --namespace monitoring \
    --set loki.serviceName=loki \
    --set loki.servicePort=3100 \
    --wait --timeout=5m

print_status "Bước 6: Đợi tất cả pods sẵn sàng..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=loki -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=promtail -n monitoring --timeout=300s

print_status "Bước 7: Cấu hình Alertmanager rules..."
kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1alpha1
kind: PrometheusRule
metadata:
  name: k8s-alerts
  namespace: monitoring
spec:
  groups:
  - name: kubernetes.rules
    rules:
    - alert: HighCPUUsage
      expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage on {{ \$labels.instance }}"
        description: "CPU usage is above 80% for 5 minutes"
    
    - alert: HighMemoryUsage
      expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage on {{ \$labels.instance }}"
        description: "Memory usage is above 85% for 5 minutes"
    
    - alert: PodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total[15m]) * 60 > 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Pod {{ \$labels.pod }} is crash looping"
        description: "Pod {{ \$labels.pod }} is restarting {{ printf \"%.2f\" \$value }} times / 5 minutes"
    
    - alert: NodeDown
      expr: up == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Node {{ \$labels.instance }} is down"
        description: "Node {{ \$labels.instance }} has been down for more than 1 minute"
EOF

print_status "Bước 8: Cấu hình Grafana datasources..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
  namespace: monitoring
data:
  datasources.yaml: |
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus-kube-prometheus-prometheus:9090
      access: proxy
      isDefault: true
    - name: Loki
      type: loki
      url: http://loki:3100
      access: proxy
EOF

print_status "Bước 9: Cấu hình Alertmanager notification..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-config
  namespace: monitoring
type: Opaque
stringData:
  alertmanager.yaml: |
    global:
      resolve_timeout: 5m
    route:
      group_by: ['alertname']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'web.hook'
    receivers:
    - name: 'web.hook'
      webhook_configs:
      - url: 'http://127.0.0.1:5001/'
    inhibit_rules:
      - source_match:
          severity: 'critical'
        target_match:
          severity: 'warning'
        equal: ['alertname', 'dev', 'instance']
EOF

print_success "Monitoring stack đã được cài đặt thành công!"

echo ""
echo "📋 Thông tin truy cập:"
echo "=========================================="
echo "🌐 Grafana: http://grafana.local (admin/admin123)"
echo "📊 Prometheus: http://prometheus.local"
echo "🚨 Alertmanager: http://alertmanager.local"
echo "📝 Loki: http://loki.local"
echo ""
echo "🔧 Các lệnh hữu ích:"
echo "   # Kiểm tra trạng thái pods"
echo "   kubectl get pods -n monitoring"
echo ""
echo "   # Xem logs Grafana"
echo "   kubectl logs -n monitoring -l app.kubernetes.io/name=grafana"
echo ""
echo "   # Xem logs Prometheus"
echo "   kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus"
echo ""
echo "   # Xem logs Loki"
echo "   kubectl logs -n monitoring -l app.kubernetes.io/name=loki"
echo ""
echo "   # Port forward để truy cập local"
echo "   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-grafana 3000:80"
echo ""
echo "🎉 Monitoring stack đã sẵn sàng!"
echo "==========================================" 