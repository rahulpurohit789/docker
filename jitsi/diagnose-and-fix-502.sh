#!/bin/bash
# Comprehensive diagnostic and fix for 502 BOSH connection errors

cd "$(dirname "$0")"

echo "=========================================="
echo "Diagnosing 502 BOSH Connection Error"
echo "=========================================="
echo ""

# 1. Check container status
echo "1. Container Status:"
docker-compose ps
echo ""

# 2. Check Prosody logs for HTTP service activation
echo "2. Prosody HTTP Service Status:"
docker-compose logs prosody | grep -i "http\|5280\|activated\|bosh\|error" | tail -10
echo ""

# 3. Check if Prosody is actually listening
echo "3. Checking if Prosody is listening on port 5280:"
docker-compose exec -T prosody sh -c 'ss -tlnp 2>/dev/null | grep 5280 || netstat -tlnp 2>/dev/null | grep 5280 || echo "Cannot check - trying alternative method"'
echo ""

# 4. Test DNS resolution from web container
echo "4. DNS Resolution Test (web -> prosody):"
docker-compose exec -T web sh -c 'getent hosts prosody'
echo ""

# 5. Test connectivity using wget or curl from web container
echo "5. Connectivity Test (web -> prosody:5280):"
docker-compose exec -T web sh -c 'wget -O- --timeout=5 --tries=1 http://prosody:5280/http-bind 2>&1 | head -5' || \
docker-compose exec -T web sh -c 'curl -v --connect-timeout 5 http://prosody:5280/http-bind 2>&1 | head -10' || \
echo "❌ Cannot connect to prosody:5280"
echo ""

# 6. Check nginx configuration in web container
echo "6. Nginx BOSH Configuration:"
docker-compose exec -T web sh -c 'grep -A 8 "location = /http-bind" /config/nginx/meet.conf | head -10'
echo ""

# 7. Check if Prosody process is running
echo "7. Prosody Process Check:"
docker-compose exec -T prosody sh -c 'ps aux | grep prosody | grep -v grep || echo "Prosody process not found"'
echo ""

# 8. Check Prosody configuration for http_ports
echo "8. Prosody HTTP Configuration:"
docker-compose exec -T prosody sh -c 'grep -E "http_ports|http_interfaces" /config/prosody.cfg.lua /config/conf.d/*.cfg.lua 2>/dev/null | head -5'
echo ""

# 9. Restart Prosody to ensure clean state
echo "9. Restarting Prosody container..."
docker-compose restart prosody
echo "Waiting 10 seconds for Prosody to fully start..."
sleep 10
echo ""

# 10. Check Prosody logs after restart
echo "10. Prosody Logs After Restart:"
docker-compose logs prosody --tail=20 | grep -i "http\|5280\|activated\|bosh\|error\|started" || echo "No relevant logs found"
echo ""

# 11. Final connectivity test
echo "11. Final Connectivity Test:"
docker-compose exec -T web sh -c 'wget -O- --timeout=5 --tries=1 http://prosody:5280/http-bind 2>&1 | head -3' || \
docker-compose exec -T web sh -c 'curl -s --connect-timeout 5 -o /dev/null -w "%{http_code}" http://prosody:5280/http-bind 2>&1' || \
echo "❌ Still cannot connect"
echo ""

echo "=========================================="
echo "Diagnosis Complete"
echo "=========================================="
echo ""
echo "If connectivity still fails, try:"
echo "  1. Restart all containers: docker-compose restart"
echo "  2. Check Prosody logs: docker-compose logs prosody"
echo "  3. Verify network: docker network inspect jitsi-meet_jitsi-meet"

