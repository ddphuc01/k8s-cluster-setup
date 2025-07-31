#!/bin/bash

echo "=== Tempo Integration Test ==="

# Check Tempo pod status
echo "1. Checking Tempo pod status..."
kubectl get pods -n monitoring | grep tempo

# Check Tempo service
echo -e "\n2. Checking Tempo service..."
kubectl get svc -n monitoring | grep tempo

# Check Grafana datasources
echo -e "\n3. Checking Grafana datasources..."
kubectl get configmap grafana-datasources -n monitoring --show-labels

# Check Tempo readiness
echo -e "\n4. Testing Tempo readiness..."
kubectl port-forward -n monitoring svc/tempo 3200:3200 &
PF_PID=$!
sleep 3
curl -s http://localhost:3200/ready
kill $PF_PID

# Check Grafana sidecar logs
echo -e "\n5. Checking Grafana sidecar logs..."
kubectl logs -n monitoring -l app=grafana -c grafana-sc-datasources --tail=5

# Check if Tempo datasource is loaded
echo -e "\n6. Checking if Tempo datasource is loaded..."
kubectl exec -n monitoring -c grafana $(kubectl get pods -n monitoring -l app=grafana -o jsonpath='{.items[0].metadata.name}') -- cat /etc/grafana/provisioning/datasources/datasources.yaml | grep -A 5 "name: Tempo"

echo -e "\n=== Test Complete ==="
echo "If you see Tempo datasource in the output above, it should be available in Grafana."
echo "Access Grafana at: http://grafana.local"
echo "Go to: Configuration > Data Sources > Tempo" 