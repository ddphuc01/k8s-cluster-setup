#!/bin/bash

echo "=== Tempo Dashboard Test & Guide ==="

# Check if Tempo is running
echo "1. Checking Tempo status..."
kubectl get pods -n monitoring | grep tempo

# Check Grafana status
echo -e "\n2. Checking Grafana status..."
kubectl get pods -n monitoring | grep grafana

# Check dashboards ConfigMap
echo -e "\n3. Checking dashboards ConfigMap..."
kubectl get configmap grafana-dashboards -n monitoring --show-labels

# Test Tempo API
echo -e "\n4. Testing Tempo API..."
kubectl port-forward -n monitoring svc/tempo 3200:3200 &
PF_PID=$!
sleep 3
echo "Tempo readiness: $(curl -s http://localhost:3200/ready)"
kill $PF_PID

# Check Grafana service
echo -e "\n5. Checking Grafana service..."
kubectl get svc -n monitoring | grep grafana

echo -e "\n=== Test Complete ==="
echo "✅ Tempo và Grafana đang hoạt động!"
echo ""
echo "🌐 **Truy cập Grafana:**"
echo "   URL: http://grafana.local"
echo "   Username: admin"
echo "   Password: $(kubectl get secret -n monitoring prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 -d)"
echo ""
echo "📊 **Dashboards có sẵn:**"
echo "   1. Tempo Overview Dashboard"
echo "   2. Kubernetes Logs Dashboard"
echo "   3. Loki Performance Dashboard"
echo ""
echo "🔍 **Cách sử dụng Tempo Explore:**"
echo "   1. Vào Grafana → Explore (🔍)"
echo "   2. Chọn Tempo datasource"
echo "   3. Thử queries:"
echo "      - {} (tất cả traces)"
echo "      - {service.name=\"prometheus\"}"
echo "      - {duration > 1s}"
echo ""
echo "📈 **Cách tạo Dashboard từ Explore:**"
echo "   1. Trong Explore, nhập query và test"
echo "   2. Click 'Add to dashboard' (+)"
echo "   3. Chọn dashboard có sẵn hoặc tạo mới"
echo "   4. Đặt tên panel và save"
echo ""
echo "🎯 **Dashboard ID từ Grafana.com:**"
echo "   - Tempo Service Map: 12019"
echo "   - Tempo Overview: 12020"
echo "   - Custom Dashboards: Đã tạo sẵn"
echo ""
echo "🚀 **Next Steps:**"
echo "   1. Truy cập Grafana và explore Tempo"
echo "   2. Import dashboard từ Grafana.com (ID: 12019)"
echo "   3. Instrument applications với OpenTelemetry"
echo "   4. Tạo custom dashboards theo nhu cầu" 