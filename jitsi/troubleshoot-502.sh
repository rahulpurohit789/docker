#!/bin/bash
# Troubleshoot 502 Bad Gateway errors for BOSH endpoint

cd "$(dirname "$0")"

echo "=========================================="
echo "Troubleshooting 502 Bad Gateway Errors"
echo "=========================================="

echo ""
echo "1. Checking container status..."
docker-compose ps

echo ""
echo "2. Checking Prosody container logs..."
docker-compose logs prosody --tail=30 | grep -E "error|Error|ERROR|failed|Failed|BOSH|http-bind" || echo "No obvious errors in recent logs"

echo ""
echo "3. Checking web/nginx error logs..."
docker-compose exec -T web cat /var/log/nginx/error.log 2>/dev/null | tail -20 || echo "Error log not accessible"

echo ""
echo "4. Testing connectivity from web to prosody..."
docker-compose exec -T web sh -c 'nc -zv prosody 5280 2>&1 || echo "nc not available, trying alternative..."' || echo "Connectivity test failed"

echo ""
echo "5. Checking BOSH configuration in meet.conf..."
docker-compose exec -T web grep -A 10 'location = /http-bind' /config/nginx/meet.conf

echo ""
echo "6. Testing BOSH endpoint directly from web container..."
docker-compose exec -T web sh -c 'echo "Testing HTTP connection to prosody:5280/http-bind..." && wget -O- http://prosody:5280/http-bind 2>&1 | head -10 || echo "wget test failed"'

echo ""
echo "7. Checking Prosody BOSH endpoint..."
docker-compose logs prosody | grep -i "http-bind\|BOSH\|5280" | tail -10

echo ""
echo "8. Checking if Prosody is listening on port 5280..."
docker-compose exec -T prosody netstat -tlnp 2>/dev/null | grep 5280 || docker-compose exec -T prosody ss -tlnp 2>/dev/null | grep 5280 || echo "Cannot check listening ports"

echo ""
echo "=========================================="
echo "Troubleshooting Complete"
echo "=========================================="

