#!/bin/bash
# Test BOSH connection directly from web container to prosody

cd "$(dirname "$0")"

echo "Testing BOSH connection..."
echo ""

# Test 1: Check if web can reach prosody
echo "1. Testing connectivity from web to prosody:5280..."
docker-compose exec -T web sh -c 'timeout 5 sh -c "echo > /dev/tcp/prosody/5280" 2>&1 && echo "✅ Connection successful" || echo "❌ Connection failed"'

# Test 2: Try HTTP request to BOSH endpoint
echo ""
echo "2. Testing HTTP request to BOSH endpoint..."
docker-compose exec -T web sh << 'TEST_SCRIPT'
echo "GET /http-bind HTTP/1.1
Host: 35.154.130.125
Connection: close

" | nc prosody 5280 2>&1 | head -10 || echo "nc test failed"
TEST_SCRIPT

# Test 3: Check nginx error logs
echo ""
echo "3. Checking nginx error logs..."
docker-compose exec -T web sh -c 'find /var/log -name "error.log" 2>/dev/null | head -1 | xargs tail -20 2>/dev/null || echo "Error log not found"'

# Test 4: Check Prosody logs for BOSH requests
echo ""
echo "4. Checking Prosody logs for BOSH requests..."
docker-compose logs prosody --tail=50 | grep -i "http-bind\|bosh\|5280\|error\|fail" | tail -10 || echo "No relevant logs found"

echo ""
echo "=========================================="
echo "Test Complete"
echo "=========================================="

