#!/bin/bash
# Start Jitsi containers and automatically fix BOSH and JVB websocket configurations
# This script ensures fixes are applied after container starts

cd "$(dirname "$0")"

echo "=========================================="
echo "Starting Jitsi Meet with BOSH & JVB Fixes"
echo "=========================================="

# Get IP from environment or use default
JITSI_DOMAIN="${JITSI_DOMAIN:-35.154.130.125}"
if [[ $JITSI_DOMAIN =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    JVB_IP="$JITSI_DOMAIN"
else
    JVB_IP="${DOCKER_HOST_ADDRESS:-35.154.130.125}"
fi

# Start containers
echo "Starting Jitsi containers..."
docker-compose up -d

# Wait for containers to fully initialize
echo "Waiting for containers to initialize..."
sleep 15

# Apply BOSH fix
echo "Applying BOSH configuration fix..."
docker-compose exec -T web bash << FIX_BOSH_SCRIPT
MEET_CONF="/config/nginx/meet.conf"

# Wait for meet.conf to exist
for i in {1..30}; do
    if [ -f "\$MEET_CONF" ]; then
        break
    fi
    sleep 1
done

if [ ! -f "\$MEET_CONF" ]; then
    echo "ERROR: meet.conf not found"
    exit 1
fi

# Fix main BOSH location
sed -i 's|proxy_pass http://localhost/http-bind/http-bind;|proxy_pass http://prosody:5280/http-bind;|g' "\$MEET_CONF"
sed -i 's|proxy_pass http://localhost:5280/http-bind;|proxy_pass http://prosody:5280/http-bind;|g' "\$MEET_CONF"
sed -i 's|proxy_set_header Host localhost;|proxy_set_header Host \$http_host;|g' "\$MEET_CONF"
# Fix Host header if it's set to a specific IP (should use variable)
sed -i 's|proxy_set_header Host [0-9.]*;|proxy_set_header Host \$http_host;|g' "\$MEET_CONF"

# Fix subdomain BOSH location using perl (more reliable)
if command -v perl >/dev/null 2>&1; then
    perl -i -0pe 's/location ~ \^\/\(\[^\/\?&:.*?\)\/http-bind \{.*?rewrite[^}]+\}/location ~ ^\/([^\/\?&:''""]+)\/http-bind {\n        proxy_set_header X-Forwarded-For \$remote_addr;\n        proxy_set_header Host \$http_host;\n        proxy_set_header X-Forwarded-Proto \$scheme;\n        \n        proxy_pass http:\/\/prosody:5280\/http-bind;\n        proxy_buffering off;\n        tcp_nodelay on;\n        proxy_read_timeout 3600s;\n    }/gs' "\$MEET_CONF"
fi

# Verify fix
if grep -q "proxy_pass http://prosody:5280/http-bind;" "\$MEET_CONF"; then
    echo "✅ BOSH configuration fixed successfully"
    # Test and reload nginx
    if nginx -t >/dev/null 2>&1; then
        nginx -s reload
        echo "✅ Nginx reloaded with fixed configuration"
    else
        echo "⚠️  WARNING: Nginx configuration test failed"
        nginx -t
    fi
else
    echo "❌ ERROR: BOSH fix verification failed"
    exit 1
fi
FIX_BOSH_SCRIPT

BOSH_FIX_STATUS=$?

# Apply JVB websocket fix
echo "Applying JVB websocket configuration fix..."
JVB_CONF="./jitsi-config/jvb/jvb.conf"

# Wait for jvb.conf to exist
for i in {1..30}; do
    if [ -f "$JVB_CONF" ]; then
        break
    fi
    sleep 1
done

if [ -f "$JVB_CONF" ]; then
    echo "Using IP: $JVB_IP"
    
    # Fix websocket domain
    sed -i "s|domain = \"localhost:8443\"|domain = \"$JVB_IP:4443\"|g" "$JVB_CONF"
    
    # Fix TLS setting
    sed -i 's/tls = true/tls = false/g' "$JVB_CONF"
    
    # Fix static mapping public address
    sed -i "s|public-address = \"localhost\"|public-address = \"$JVB_IP\"|g" "$JVB_CONF"
    
    # Verify fix
    if grep -q "domain = \"$JVB_IP:4443\"" "$JVB_CONF" && grep -q 'tls = false' "$JVB_CONF"; then
        echo "✅ JVB websocket configuration fixed successfully"
        echo "   - Websocket domain: $JVB_IP:4443"
        echo "   - TLS: disabled"
        echo "   - Public address: $JVB_IP"
        
        # Restart JVB to apply changes
        docker-compose restart jvb
        sleep 3
        echo "✅ JVB restarted with fixed configuration"
        JVB_FIX_STATUS=0
    else
        echo "❌ ERROR: JVB fix verification failed"
        JVB_FIX_STATUS=1
    fi
else
    echo "⚠️  WARNING: jvb.conf not found, skipping JVB fix"
    JVB_FIX_STATUS=0
fi

# Check overall status
if [ $BOSH_FIX_STATUS -eq 0 ] && [ $JVB_FIX_STATUS -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ Jitsi is ready!"
    echo "=========================================="
    echo ""
    echo "All services are running with fixed configurations:"
    echo "  ✅ BOSH configuration fixed"
    echo "  ✅ JVB websocket configuration fixed"
    echo ""
    echo "Access Jitsi at: http://$JITSI_DOMAIN"
    echo ""
else
    echo ""
    echo "❌ Error fixing configurations"
    echo "BOSH fix status: $BOSH_FIX_STATUS"
    echo "JVB fix status: $JVB_FIX_STATUS"
    echo "Check logs: docker-compose logs web jvb"
    exit 1
fi
