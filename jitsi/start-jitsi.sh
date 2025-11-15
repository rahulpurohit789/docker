#!/bin/bash
# Start Jitsi with environment-aware configuration

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
sleep 20

# Get domain for fixes
DOMAIN="$JITSI_DOMAIN"
JVB_IP="$DOCKER_HOST_ADDRESS"

echo ""
echo "Environment: $ENVIRONMENT"
echo "Domain: $DOMAIN"
echo "JVB IP: $JVB_IP"
echo ""

# Ensure our fixed meet.conf is used and protected
echo "Ensuring fixed meet.conf is used..."
docker-compose exec -T web bash -c "
MEET_CONF=/config/nginx/meet.conf
FIXED_TEMPLATE=/config/nginx/meet.conf

# Wait for container's generated meet.conf
for i in {1..30}; do
    if [ -f \$MEET_CONF ]; then
        # Jitsi has generated it, now replace with our fixed version
        # Our fixed version is already mounted from host
        # Just make it read-only to prevent overwrites
        chmod 444 \$MEET_CONF
        echo '✅ meet.conf is protected (read-only)'
        break
    fi
    sleep 1
done

if [ ! -f \$MEET_CONF ]; then
    echo '⚠️  Warning: meet.conf not found after 30 seconds'
fi

# Test nginx config
nginx -t 2>&1 && echo '✅ Nginx config test passed' || echo '❌ Nginx config test failed'
nginx -s reload 2>&1 || true
"

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
