#!/bin/bash

echo "=== Testing Tempo Datasource ==="

# Check current Grafana pod
GRAFANA_POD=$(kubectl get pods -n monitoring -l app=grafana -o jsonpath='{.items[0].metadata.name}')
echo "Grafana Pod: $GRAFANA_POD"

# Check datasources file
echo -e "\n1. Checking datasources configuration..."
kubectl exec -n monitoring $GRAFANA_POD -c grafana -- cat /etc/grafana/provisioning/datasources/datasources.yaml

# Check if Tempo datasource is loaded
echo -e "\n2. Checking if Tempo datasource is loaded..."
kubectl exec -n monitoring $GRAFANA_POD -c grafana -- cat /etc/grafana/provisioning/datasources/datasources.yaml | grep -A 10 "name: Tempo"

# Check Grafana logs for Tempo
echo -e "\n3. Checking Grafana logs for Tempo..."
kubectl logs -n monitoring $GRAFANA_POD -c grafana --tail=10 | grep -i tempo

# Test Tempo connectivity
echo -e "\n4. Testing Tempo connectivity..."
kubectl port-forward -n monitoring svc/tempo 3200:3200 &
PF_PID=$!
sleep 3
echo "Tempo readiness: $(curl -s http://localhost:3200/ready)"
kill $PF_PID

echo -e "\n=== Test Complete ==="
echo "If you see Tempo datasource with UID 'tempo', it should work correctly."
echo "Access Grafana at: http://grafana.local"
echo "Go to: Configuration > Data Sources > Tempo"
echo "Check if 'Trace to logs' and 'Trace to metrics' show correct datasources." 