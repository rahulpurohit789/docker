#!/bin/bash
# Start Jitsi containers and automatically fix BOSH configuration
# This script ensures BOSH fix is applied after container starts

cd "$(dirname "$0")"

echo "=========================================="
echo "Starting Jitsi Meet with BOSH Fix"
echo "=========================================="

# Start containers
echo "Starting Jitsi containers..."
docker-compose up -d

# Wait for containers to fully initialize
echo "Waiting for containers to initialize..."
sleep 15

# Apply BOSH fix
echo "Applying BOSH configuration fix..."
docker-compose exec -T web bash << 'FIX_SCRIPT'
MEET_CONF="/config/nginx/meet.conf"

# Wait for meet.conf to exist
for i in {1..30}; do
    if [ -f "$MEET_CONF" ]; then
        break
    fi
    sleep 1
done

if [ ! -f "$MEET_CONF" ]; then
    echo "ERROR: meet.conf not found"
    exit 1
fi

# Fix main BOSH location
sed -i 's|proxy_pass http://localhost/http-bind/http-bind;|proxy_pass http://prosody:5280/http-bind;|g' "$MEET_CONF"
sed -i 's|proxy_pass http://localhost:5280/http-bind;|proxy_pass http://prosody:5280/http-bind;|g' "$MEET_CONF"
sed -i 's|proxy_set_header Host localhost;|proxy_set_header Host $http_host;|g' "$MEET_CONF"

# Fix subdomain BOSH location using perl (more reliable)
if command -v perl >/dev/null 2>&1; then
    perl -i -0pe 's/location ~ \^\/\(\[^\/\?&:.*?\)\/http-bind \{.*?rewrite[^}]+\}/location ~ ^\/([^\/\?&:''""]+)\/http-bind {\n        proxy_set_header X-Forwarded-For \$remote_addr;\n        proxy_set_header Host \$http_host;\n        proxy_set_header X-Forwarded-Proto \$scheme;\n        \n        proxy_pass http:\/\/prosody:5280\/http-bind;\n        proxy_buffering off;\n        tcp_nodelay on;\n        proxy_read_timeout 3600s;\n    }/gs' "$MEET_CONF"
fi

# Verify fix
if grep -q "proxy_pass http://prosody:5280/http-bind;" "$MEET_CONF"; then
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
    echo "❌ ERROR: Fix verification failed"
    exit 1
fi
FIX_SCRIPT

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ Jitsi is ready!"
    echo "=========================================="
    echo ""
    echo "Access Jitsi at: http://localhost"
    echo "Or: http://$(hostname -I | awk '{print $1}')"
    echo ""
    echo "All services are running with fixed BOSH configuration."
else
    echo ""
    echo "❌ Error fixing BOSH configuration"
    echo "Check logs: docker-compose logs web"
    exit 1
fi

