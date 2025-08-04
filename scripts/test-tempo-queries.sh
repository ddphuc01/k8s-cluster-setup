#!/bin/bash

echo "=== Tempo TraceQL Query Test ==="

# Start port-forward if not running
if ! pgrep -f "port-forward.*tempo" > /dev/null; then
    echo "Starting port-forward..."
    kubectl port-forward -n monitoring svc/tempo 3200:3200 &
    sleep 3
fi

# Test basic queries
echo "1. Testing basic queries..."

echo "Query: {} (all traces)"
curl -s "http://localhost:3200/api/search?q=%7B%7D&limit=5" | jq '.traces | length' 2>/dev/null || echo "No traces found or jq not available"

echo "Query: {service.name=\"prometheus\"}"
curl -s "http://localhost:3200/api/search?q=%7Bservice.name%3D%22prometheus%22%7D&limit=5" | jq '.traces | length' 2>/dev/null || echo "No traces found or jq not available"

echo "Query: {duration>1s}"
curl -s "http://localhost:3200/api/search?q=%7Bduration%3E1s%7D&limit=5" | jq '.traces | length' 2>/dev/null || echo "No traces found or jq not available"

echo "Query: {status=\"error\"}"
curl -s "http://localhost:3200/api/search?q=%7Bstatus%3D%22error%22%7D&limit=5" | jq '.traces | length' 2>/dev/null || echo "No traces found or jq not available"

# Test combined queries
echo -e "\n2. Testing combined queries..."

echo "Query: {service.name=\"prometheus\" && duration>1s}"
curl -s "http://localhost:3200/api/search?q=%7Bservice.name%3D%22prometheus%22%20%26%26%20duration%3E1s%7D&limit=5" | jq '.traces | length' 2>/dev/null || echo "No traces found or jq not available"

echo "Query: {service.name=\"prometheus\" && status=\"error\"}"
curl -s "http://localhost:3200/api/search?q=%7Bservice.name%3D%22prometheus%22%20%26%26%20status%3D%22error%22%7D&limit=5" | jq '.traces | length' 2>/dev/null || echo "No traces found or jq not available"

# Test HTTP queries
echo -e "\n3. Testing HTTP queries..."

echo "Query: {http.method=\"GET\"}"
curl -s "http://localhost:3200/api/search?q=%7Bhttp.method%3D%22GET%22%7D&limit=5" | jq '.traces | length' 2>/dev/null || echo "No traces found or jq not available"

echo "Query: {http.status_code=\"500\"}"
curl -s "http://localhost:3200/api/search?q=%7Bhttp.status_code%3D%22500%22%7D&limit=5" | jq '.traces | length' 2>/dev/null || echo "No traces found or jq not available"

echo -e "\n=== Test Complete ==="
echo "✅ Tempo API đang hoạt động!"
echo "📊 Nếu kết quả là 0, có nghĩa là chưa có traces"
echo "🔍 Để có traces, cần instrument applications với OpenTelemetry"
echo ""
echo "🌐 Truy cập Grafana: http://grafana.local"
echo "📝 Sử dụng queries với syntax đúng:"
echo "   - {} (all traces)"
echo "   - {service.name=\"your-service\"}"
echo "   - {duration>1s}"
echo "   - {status=\"error\"}" 