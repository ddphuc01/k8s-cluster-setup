#!/bin/bash

echo "=== Debug TraceQL Syntax ==="

# Start port-forward if not running
if ! pgrep -f "port-forward.*tempo" > /dev/null; then
    echo "Starting port-forward..."
    kubectl port-forward -n monitoring svc/tempo 3200:3200 &
    sleep 3
fi

echo "Testing different TraceQL syntax formats..."

# Test 1: Basic service name
echo "1. Testing: {service.name=\"prometheus\"}"
curl -s "http://localhost:3200/api/search?q=%7Bservice.name%3D%22prometheus%22%7D&limit=1" | jq '.traces | length' 2>/dev/null || echo "Error or no traces"

# Test 2: Duration with ms
echo "2. Testing: {duration>100ms}"
curl -s "http://localhost:3200/api/search?q=%7Bduration%3E100ms%7D&limit=1" | jq '.traces | length' 2>/dev/null || echo "Error or no traces"

# Test 3: Duration with seconds
echo "3. Testing: {duration>0.1s}"
curl -s "http://localhost:3200/api/search?q=%7Bduration%3E0.1s%7D&limit=1" | jq '.traces | length' 2>/dev/null || echo "Error or no traces"

# Test 4: Duration with milliseconds
echo "4. Testing: {duration>100000000}"
curl -s "http://localhost:3200/api/search?q=%7Bduration%3E100000000%7D&limit=1" | jq '.traces | length' 2>/dev/null || echo "Error or no traces"

# Test 5: Combined query with seconds
echo "5. Testing: {service.name=\"prometheus\" && duration>0.1s}"
curl -s "http://localhost:3200/api/search?q=%7Bservice.name%3D%22prometheus%22%20%26%26%20duration%3E0.1s%7D&limit=1" | jq '.traces | length' 2>/dev/null || echo "Error or no traces"

# Test 6: Combined query with nanoseconds
echo "6. Testing: {service.name=\"prometheus\" && duration>100000000}"
curl -s "http://localhost:3200/api/search?q=%7Bservice.name%3D%22prometheus%22%20%26%26%20duration%3E100000000%7D&limit=1" | jq '.traces | length' 2>/dev/null || echo "Error or no traces"

# Test 7: Range query with seconds
echo "7. Testing: {service.name=\"prometheus\" && duration>0.1s && duration<1.2s}"
curl -s "http://localhost:3200/api/search?q=%7Bservice.name%3D%22prometheus%22%20%26%26%20duration%3E0.1s%20%26%26%20duration%3C1.2s%7D&limit=1" | jq '.traces | length' 2>/dev/null || echo "Error or no traces"

# Test 8: Simple duration range
echo "8. Testing: {duration>0.1s && duration<1.2s}"
curl -s "http://localhost:3200/api/search?q=%7Bduration%3E0.1s%20%26%26%20duration%3C1.2s%7D&limit=1" | jq '.traces | length' 2>/dev/null || echo "Error or no traces"

echo -e "\n=== Debug Complete ==="
echo "✅ Nếu tất cả đều trả về 0, có nghĩa là chưa có traces"
echo "❌ Nếu có lỗi, kiểm tra syntax của query tương ứng"
echo ""
echo "📝 **Syntax đúng cho duration:**"
echo "   - {duration>0.1s}     # Sử dụng seconds"
echo "   - {duration>100ms}    # Sử dụng milliseconds"
echo "   - {duration>100000000} # Sử dụng nanoseconds"
echo ""
echo "🔍 **Test trong Grafana với:**"
echo "   {service.name=\"prometheus\" && duration>0.1s && duration<1.2s}" 