#!/bin/bash
# Start Jitsi with environment-aware configuration

cd "$(dirname "$0")"

echo "=========================================="
echo "Starting Jitsi Meet"
echo "=========================================="
echo ""

# Setup environment
source ./setup-env.sh || exit 1

# Prepare our fixed meet.conf and create a backup
echo "Preparing meet.conf..."
MEET_CONF_HOST="./jitsi-config/web/nginx/meet.conf"
FIXED_BACKUP="./jitsi-config/web/nginx/meet.conf.fixed"

if [ -f "$MEET_CONF_HOST" ]; then
    # Make it writable temporarily (in case it was read-only from previous run)
    chmod 644 "$MEET_CONF_HOST" 2>/dev/null || true
    
    # Create a backup of our fixed version (this will be used by the container script)
    cp "$MEET_CONF_HOST" "$FIXED_BACKUP" 2>/dev/null || true
    
    # Verify our fixed version has the correct BOSH config (new pattern with rewrite to strip query params)
    if grep -q 'rewrite ^/http-bind$ /http-bind break;' "$MEET_CONF_HOST" && grep -q 'proxy_pass http://prosody:5280;$' "$MEET_CONF_HOST"; then
        echo "✅ meet.conf exists and has our fixed configuration"
    else
        echo "❌ ERROR: meet.conf does not have our fixed BOSH configuration!"
        echo "    Please restore from git: git checkout -- jitsi-config/web/nginx/meet.conf"
        exit 1
    fi
else
    echo "❌ ERROR: meet.conf not found on host!"
    exit 1
fi

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

# Wait for container restore scripts to complete
# 20-restore-meet-conf.sh runs after Jitsi's 10-config and restores our fixed version
# 99-protect-meet-conf.sh runs last and does final verification
echo "Waiting for container restore scripts to complete..."
sleep 15  # Give time for 20-restore-meet-conf.sh and 99-protect-meet-conf.sh to run

# Verify meet.conf in container has our fixed configuration
echo "Verifying meet.conf in container..."
docker-compose exec -T web bash -c "
MEET_CONF=/config/nginx/meet.conf
FIXED_CONF=/config/nginx/meet.conf.fixed

# Check if file has our fixed BOSH configuration (new pattern with rewrite to strip query params)
if grep -q 'rewrite ^/http-bind$ /http-bind break;' \$MEET_CONF && grep -q 'proxy_pass http://prosody:5280;$' \$MEET_CONF; then
    echo '✅ Container meet.conf has our fixed configuration'
else
    echo '⚠️  Container meet.conf is still wrong - restoring now...'
    
    # Try to restore from fixed backup (created by start-jitsi.sh on host)
    if [ -f \$FIXED_CONF ]; then
        chmod 644 \$MEET_CONF 2>/dev/null || true
        cp \$FIXED_CONF \$MEET_CONF
        echo '✅ Restored from container backup'
    else
        echo '⚠️  Fixed backup not found - will be created by protection script'
    fi
fi

# Test nginx config
if nginx -t 2>&1; then
    echo '✅ Nginx config test passed'
    nginx -s reload 2>&1 || true
else
    echo '❌ Nginx config test failed'
    nginx -t 2>&1 | head -10
fi
"

# Final check: If host file was overwritten (shouldn't happen since we have protection scripts)
if [ -f "$MEET_CONF_HOST" ]; then
    if ! grep -q 'rewrite ^/http-bind$ /http-bind break;' "$MEET_CONF_HOST" || ! grep -q 'proxy_pass http://prosody:5280;$' "$MEET_CONF_HOST"; then
        echo "⚠️  Host meet.conf was overwritten - restoring from git..."
        chmod 644 "$MEET_CONF_HOST" 2>/dev/null || true
        git checkout -- "$MEET_CONF_HOST" 2>/dev/null || {
            echo "⚠️  Could not restore from git - manual restore needed"
        }
        # Re-create backup
        cp "$MEET_CONF_HOST" "$FIXED_BACKUP" 2>/dev/null || true
        echo "✅ Host meet.conf restored and backup updated"
    fi
    
    # Make it read-only on HOST (final protection)
    # Note: This may not prevent root from writing, but helps
    chmod 444 "$MEET_CONF_HOST" 2>/dev/null || true
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
