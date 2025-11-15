#!/bin/bash
# Start Jitsi with environment-aware configuration
# Automatically fixes BOSH and JVB websocket based on environment

cd "$(dirname "$0")"

echo "=========================================="
echo "Starting Jitsi Meet"
echo "=========================================="
echo ""

# Setup environment
source ./setup-env.sh || exit 1

echo ""
echo "Starting Jitsi containers..."
docker-compose up -d

# Wait for containers to initialize
echo ""
echo "Waiting for containers to initialize..."
sleep 15

# Get domain for fixes
DOMAIN="$JITSI_DOMAIN"
JVB_IP="$DOCKER_HOST_ADDRESS"

echo ""
echo "Applying configuration fixes..."
echo "   Environment: $ENVIRONMENT"
echo "   Domain: $DOMAIN"
echo "   JVB IP: $JVB_IP"
echo ""

# Apply BOSH fix
echo "1. Fixing BOSH configuration..."
docker-compose exec -T web bash << EOF
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

# Remove incorrect BOSH location blocks
perl -i -0pe 's/location = \/http-bind \{.*?\n\}//gs' "\$MEET_CONF" 2>/dev/null || true
perl -i -0pe 's/location ~ \^\/\(\[^\/\?&:'"'"'"]+\)\/http-bind \{.*?\n\}//gs' "\$MEET_CONF" 2>/dev/null || true

# Fix Host header if it's set to a specific IP
sed -i 's|proxy_set_header Host [0-9.]*;|proxy_set_header Host \$http_host;|g' "\$MEET_CONF"
sed -i 's|proxy_set_header Host localhost;|proxy_set_header Host \$http_host;|g' "\$MEET_CONF"

# Find insertion point (before colibri websockets section)
INSERT_LINE=\$(grep -n '# colibri (JVB) websockets' "\$MEET_CONF" | head -1 | cut -d: -f1)
if [ -z "\$INSERT_LINE" ]; then
    INSERT_LINE=\$(wc -l < "\$MEET_CONF")
fi

# Insert correct BOSH configuration
sed -i "\${INSERT_LINE}i\\
# BOSH - Fixed configuration\\
location = /http-bind {\\
    proxy_set_header X-Forwarded-For \$remote_addr;\\
    proxy_set_header Host \$http_host;\\
    proxy_set_header X-Forwarded-Proto \$scheme;\\
\\
    proxy_pass http://prosody:5280/http-bind;\\
    proxy_buffering off;\\
    tcp_nodelay on;\\
    proxy_read_timeout 3600s;\\
}\\
\\
# BOSH - Subdomain support\\
location ~ ^/([^/?&:'"'"'"]+)/http-bind {\\
    proxy_set_header X-Forwarded-For \$remote_addr;\\
    proxy_set_header Host \$http_host;\\
    proxy_set_header X-Forwarded-Proto \$scheme;\\
\\
    proxy_pass http://prosody:5280/http-bind;\\
    proxy_buffering off;\\
    tcp_nodelay on;\\
    proxy_read_timeout 3600s;\\
}\\
" "\$MEET_CONF"

# Test and reload nginx
if nginx -t 2>/dev/null; then
    nginx -s reload 2>/dev/null || true
    echo "✅ BOSH configuration fixed and nginx reloaded"
else
    echo "❌ ERROR: nginx configuration test failed"
    exit 1
fi
EOF

if [ $? -ne 0 ]; then
    echo "❌ Failed to fix BOSH configuration"
    exit 1
fi

# Apply JVB WebSocket fix
echo ""
echo "2. Fixing JVB WebSocket configuration..."
docker-compose exec -T jvb bash << EOF
JVB_CONF="/config/jvb.conf"

if [ ! -f "\$JVB_CONF" ]; then
    echo "ERROR: jvb.conf not found"
    exit 1
fi

# Determine protocol and port based on environment
if [ "$ENVIRONMENT" = "development" ]; then
    WS_DOMAIN="localhost:8443"
    WS_TLS="true"
else
    WS_DOMAIN="$JVB_IP:4443"
    WS_TLS="false"
fi

# Update websocket domain
sed -i 's|domain = ".*"|domain = "'"\$WS_DOMAIN"'"|g' "\$JVB_CONF"
sed -i 's|tls = .*|tls = '\$WS_TLS'|g' "\$JVB_CONF"

# Update static mapping public address
sed -i 's|public-address = ".*"|public-address = "'"$JVB_IP"'"|g' "\$JVB_CONF"

echo "✅ JVB WebSocket configuration updated:"
echo "   Domain: \$WS_DOMAIN"
echo "   TLS: \$WS_TLS"
echo "   Public Address: $JVB_IP"
EOF

if [ $? -ne 0 ]; then
    echo "❌ Failed to fix JVB WebSocket configuration"
    exit 1
fi

# Restart JVB to apply changes
echo ""
echo "3. Restarting JVB to apply WebSocket changes..."
docker-compose restart jvb
sleep 5

echo ""
echo "=========================================="
echo "✅ Jitsi is ready!"
echo "=========================================="
echo ""
echo "Environment: $ENVIRONMENT"
echo "Access URL: http://$DOMAIN"
echo ""
echo "Containers status:"
docker-compose ps
echo ""
