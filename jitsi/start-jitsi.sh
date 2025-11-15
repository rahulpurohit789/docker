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

# Remove ALL BOSH location blocks (including malformed single-line ones)
# Remove main BOSH block (any format)
sed -i '/location = \/http-bind {/,/^}/d' "\$MEET_CONF"
sed -i '/# BOSH - Fixed configurationlocation = \/http-bind/,/^}/d' "\$MEET_CONF"
# Remove subdomain BOSH blocks
sed -i '/location ~ \^\/\(\[^\/\?&:'"'"'"]\+\)\/http-bind/,/^}/d' "\$MEET_CONF"
# Remove single-line malformed blocks (including comments on same line)
sed -i '/# BOSH.*location = \/http-bind.*{.*}/d' "\$MEET_CONF"
sed -i '/location = \/http-bind.*{.*proxy_pass.*}/d' "\$MEET_CONF"

# Fix Host header if it's set to a specific IP
sed -i 's|proxy_set_header Host [0-9.]*;|proxy_set_header Host \$http_host;|g' "\$MEET_CONF"
sed -i 's|proxy_set_header Host localhost;|proxy_set_header Host \$http_host;|g' "\$MEET_CONF"
# Fix empty proxy_set_header values
sed -i 's|proxy_set_header X-Forwarded-For ;|proxy_set_header X-Forwarded-For \$remote_addr;|g' "\$MEET_CONF"
sed -i 's|proxy_set_header Host ;|proxy_set_header Host \$http_host;|g' "\$MEET_CONF"
sed -i 's|proxy_set_header X-Forwarded-Proto ;|proxy_set_header X-Forwarded-Proto \$scheme;|g' "\$MEET_CONF"
# Remove proxy_method POST (not supported in some nginx versions, POST is default anyway)
sed -i '/proxy_method POST;/d' "\$MEET_CONF"

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
    proxy_http_version 1.1;\\
    proxy_pass_request_headers on;\\
    proxy_pass_request_body on;\\
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
    proxy_http_version 1.1;\\
    proxy_pass_request_headers on;\\
    proxy_pass_request_body on;\\
}\\
" "\$MEET_CONF"

# Fix meeting room routing to serve index.html
# Remove any @root_path location block first
sed -i '/location @root_path {/,/^}/d' "\$MEET_CONF"
# Remove any references to @root_path
sed -i '/@root_path/d' "\$MEET_CONF"

# Fix try_files directive to serve index.html directly
sed -i 's|try_files \$uri @root_path;|try_files \$uri \$uri/ /index.html;|g' "\$MEET_CONF"
sed -i 's|try_files \$uri;|try_files \$uri \$uri/ /index.html;|g' "\$MEET_CONF"

# Replace meeting room location block with proper configuration
# Use sed instead of perl to avoid escaping issues
# Remove old meeting room location block
sed -i '/location ~ \^\/\(\[^\/\?&:'"'"'"]\+\)\$/,/^}/d' "\$MEET_CONF"
sed -i '/location ~.*\[^\/\?&:'"'"'"]\+.*\$/,/^}/d' "\$MEET_CONF"

# Find insertion point (after colibri websockets)
MEETING_LINE=\$(grep -n '# colibri (JVB) websockets' "\$MEET_CONF" | head -1 | cut -d: -f1)
if [ -n "\$MEETING_LINE" ]; then
    # Find the line after the colibri location block ends (find closing brace)
    AFTER_COLIBRI=\$(awk "NR > \$MEETING_LINE && /^}/ {print NR+1; exit}" "\$MEET_CONF")
    if [ -z "\$AFTER_COLIBRI" ]; then
        # If can't find closing brace, insert after a few lines
        AFTER_COLIBRI=\$((MEETING_LINE + 10))
    fi
    # Insert the meeting room routing block
    sed -i "\${AFTER_COLIBRI}i\\
\\
# Meeting room routing - serve index.html\\
location ~ ^/([^/?&:'"'"'"]+)\$ {\\
    try_files \$uri \$uri/ /index.html;\\
}\\
" "\$MEET_CONF"
else
    # If colibri section not found, append at end
    echo "" >> "\$MEET_CONF"
    echo "# Meeting room routing - serve index.html" >> "\$MEET_CONF"
    echo "location ~ ^/([^/?&:'"'"'"]+)\$ {" >> "\$MEET_CONF"
    echo "    try_files \$uri \$uri/ /index.html;" >> "\$MEET_CONF"
    echo "}" >> "\$MEET_CONF"
fi

# Ensure root is set correctly (should already be set, but verify)
if ! grep -q "^root /usr/share/jitsi-meet;" "\$MEET_CONF"; then
    # Add root directive if missing (unlikely)
    sed -i '/^server_name/a\
root /usr/share/jitsi-meet;' "\$MEET_CONF"
fi

# Test and reload nginx
echo "Testing nginx configuration..."
if nginx -t 2>&1; then
    nginx -s reload 2>&1 || echo "⚠️  Warning: nginx reload failed, but config test passed"
    echo "✅ BOSH configuration and meeting room routing fixed - nginx reloaded"
    
    # Verify meeting room location block exists
    if grep -q "location ~ ^/(\[^/\]\+)$" "\$MEET_CONF" && grep -q "try_files.*/index.html" "\$MEET_CONF"; then
        echo "✅ Meeting room routing verified"
    else
        echo "⚠️  Warning: Meeting room routing may not be properly configured"
    fi
else
    echo "❌ ERROR: nginx configuration test failed"
    echo "Showing first 30 lines of meet.conf around meeting room block:"
    grep -n -A 5 -B 5 "location.*\[^/\]" "\$MEET_CONF" | head -30
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
