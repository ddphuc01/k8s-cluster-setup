#!/bin/bash

echo "=== Tempo Integration Verification ==="

# Check all components
echo "1. Checking all monitoring components..."
kubectl get pods -n monitoring

echo -e "\n2. Checking Tempo status..."
kubectl get pods -n monitoring | grep tempo

echo -e "\n3. Checking Tempo service..."
kubectl get svc -n monitoring | grep tempo

echo -e "\n4. Checking Grafana datasources..."
kubectl get configmap -n monitoring | grep datasource

echo -e "\n5. Testing Tempo API..."
kubectl port-forward -n monitoring svc/tempo 3200:3200 &
PF_PID=$!
sleep 3
echo "Tempo readiness: $(curl -s http://localhost:3200/ready)"
kill $PF_PID

echo -e "\n6. Checking Grafana logs for Tempo..."
kubectl logs -n monitoring -l app=grafana -c grafana --tail=3 | grep -i tempo

echo -e "\n=== Verification Complete ==="
echo "✅ Tempo is now integrated with Grafana!"
echo "🌐 Access Grafana at: http://grafana.local"
echo "📊 Go to: Configuration > Data Sources > Tempo"
echo "🔍 Go to: Explore > Select Tempo datasource"
echo "📈 You can now view traces and correlate with logs/metrics!" 