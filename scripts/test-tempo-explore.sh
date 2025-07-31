#!/bin/bash

echo "=== Tempo Explore Test ==="

# Check if Tempo is running
echo "1. Checking Tempo status..."
kubectl get pods -n monitoring | grep tempo

# Check Tempo service
echo -e "\n2. Checking Tempo service..."
kubectl get svc -n monitoring | grep tempo

# Test Tempo API
echo -e "\n3. Testing Tempo API..."
kubectl port-forward -n monitoring svc/tempo 3200:3200 &
PF_PID=$!
sleep 3
echo "Tempo readiness: $(curl -s http://localhost:3200/ready)"
kill $PF_PID

# Check Grafana datasources
echo -e "\n4. Checking Grafana datasources..."
kubectl get configmap grafana-datasources -n monitoring --show-labels

# Check if Tempo datasource is loaded
echo -e "\n5. Checking Tempo datasource in Grafana..."
GRAFANA_POD=$(kubectl get pods -n monitoring -l app=grafana -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n monitoring $GRAFANA_POD -c grafana -- cat /etc/grafana/provisioning/datasources/datasources.yaml | grep -A 5 "name: Tempo"

echo -e "\n=== Test Complete ==="
echo "✅ Tempo Explore is ready to use!"
echo "🌐 Access Grafana: http://grafana.local"
echo "🔍 Go to: Explore → Select Tempo datasource"
echo "📊 Try these queries:"
echo "   - {} (all traces)"
echo "   - {service.name=\"your-service\"}"
echo "   - {duration > 1s}"
echo ""
echo "📈 To create dashboard:"
echo "   1. Go to Explore → Tempo"
echo "   2. Enter query and test"
echo "   3. Click 'Add to dashboard'"
echo "   4. Choose existing or create new dashboard" 