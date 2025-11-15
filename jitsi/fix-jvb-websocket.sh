#!/bin/bash
# Fix JVB websocket configuration to use EC2 IP instead of localhost
# This script fixes the websocket domain and static mapping in jvb.conf

cd "$(dirname "$0")"

JVB_CONF="./jitsi-config/jvb/jvb.conf"
JITSI_DOMAIN="${JITSI_DOMAIN:-35.154.130.125}"

# Extract IP from JITSI_DOMAIN if it's an IP address
if [[ $JITSI_DOMAIN =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    JVB_IP="$JITSI_DOMAIN"
else
    # If it's a domain, try to resolve it or use from environment
    JVB_IP="${DOCKER_HOST_ADDRESS:-35.154.130.125}"
fi

if [ ! -f "$JVB_CONF" ]; then
    echo "ERROR: jvb.conf not found at $JVB_CONF"
    exit 1
fi

echo "Fixing JVB websocket configuration..."
echo "Using IP: $JVB_IP"

# Fix websocket domain (change from localhost:8443 to IP:4443)
sed -i "s|domain = \"localhost:8443\"|domain = \"$JVB_IP:4443\"|g" "$JVB_CONF"

# Fix TLS setting (change from true to false for HTTP)
sed -i 's/tls = true/tls = false/g' "$JVB_CONF"

# Fix static mapping public address
sed -i "s|public-address = \"localhost\"|public-address = \"$JVB_IP\"|g" "$JVB_CONF"

# Verify fix
if grep -q "domain = \"$JVB_IP:4443\"" "$JVB_CONF" && grep -q 'tls = false' "$JVB_CONF"; then
    echo "✅ JVB websocket configuration fixed successfully"
    echo "   - Websocket domain: $JVB_IP:4443"
    echo "   - TLS: disabled"
    echo "   - Public address: $JVB_IP"
    
    # Restart JVB to apply changes if container is running
    if docker-compose ps jvb | grep -q "Up"; then
        echo "Restarting JVB container to apply changes..."
        docker-compose restart jvb
        echo "✅ JVB restarted"
    else
        echo "⚠️  JVB container not running, configuration will be applied on next start"
    fi
else
    echo "❌ ERROR: Fix verification failed"
    exit 1
fi

