#!/bin/bash
# Quick fix for BOSH 502 Bad Gateway error
# Fixes Host header issue in nginx configuration

cd "$(dirname "$0")"

echo "Fixing BOSH Host header issue..."

# Fix the Host header in meet.conf
docker-compose exec -T web bash << 'FIX_SCRIPT'
MEET_CONF="/config/nginx/meet.conf"

if [ ! -f "$MEET_CONF" ]; then
    echo "ERROR: meet.conf not found"
    exit 1
fi

# Fix Host header - change literal IP to variable
sed -i 's|proxy_set_header Host [0-9.]*;|proxy_set_header Host $http_host;|g' "$MEET_CONF"

# Verify fix
if grep -A 5 'location = /http-bind' "$MEET_CONF" | grep -q 'proxy_set_header Host \$http_host'; then
    echo "✅ Host header fixed successfully"
    
    # Test and reload nginx
    if nginx -t >/dev/null 2>&1; then
        nginx -s reload
        echo "✅ Nginx reloaded with fixed configuration"
    else
        echo "⚠️  WARNING: Nginx configuration test failed"
        nginx -t
    fi
else
    echo "❌ ERROR: Host header fix verification failed"
    echo "Current configuration:"
    grep -A 5 'location = /http-bind' "$MEET_CONF"
    exit 1
fi
FIX_SCRIPT

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ BOSH Host header fixed successfully!"
    echo "✅ Please refresh your browser and try again"
else
    echo ""
    echo "❌ Error fixing Host header"
    exit 1
fi

