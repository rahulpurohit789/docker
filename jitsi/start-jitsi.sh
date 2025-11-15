#!/bin/bash
# Start Jitsi containers and automatically fix BOSH configuration

cd "$(dirname "$0")"

echo "Starting Jitsi containers..."
docker-compose up -d

echo "Waiting for containers to start..."
sleep 8

echo "Fixing BOSH configuration..."
# Execute the script content directly to avoid Windows/Git Bash path issues
docker-compose exec -T web sh << 'SCRIPT_END'
MEET_CONF="/config/nginx/meet.conf"
sleep 2
if [ ! -f "$MEET_CONF" ]; then
    echo "[BOSH Fix] ERROR: meet.conf not found"
    exit 1
fi
echo "[BOSH Fix] Removing incorrect BOSH location blocks..."
perl -i -0pe 's/location = \/http-bind \{.*?\n\}//gs' "$MEET_CONF"
INSERT_LINE=$(grep -n '# colibri (JVB) websockets' "$MEET_CONF" | head -1 | cut -d: -f1)
if [ -n "$INSERT_LINE" ]; then
    sed -i "${INSERT_LINE}i\\
# BOSH - Fixed to use prosody service\\
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
" "$MEET_CONF"
else
    cat >> "$MEET_CONF" << 'EOF'

# BOSH - Fixed to use prosody service
location = /http-bind {
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Proto $scheme;

    proxy_pass http://prosody:5280/http-bind;
    proxy_buffering off;
    tcp_nodelay on;
    proxy_read_timeout 3600s;
}
EOF
fi
if grep -q "proxy_pass http://prosody:5280/http-bind;" "$MEET_CONF"; then
    echo "[BOSH Fix] Configuration verified successfully"
    nginx -s reload 2>/dev/null || true
else
    echo "[BOSH Fix] ERROR: Fix verification failed"
    exit 1
fi
SCRIPT_END

if [ $? -eq 0 ]; then
    echo "✅ BOSH configuration fixed successfully!"
    echo "✅ Jitsi is ready to use!"
else
    echo "❌ Error fixing BOSH configuration"
    exit 1
fi

