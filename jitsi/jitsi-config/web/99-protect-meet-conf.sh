#!/usr/bin/with-contenv bash
# Final protection - ensure meet.conf has our fixed version
# This script runs last (99-*) to do final verification

MEET_CONF="/config/nginx/meet.conf"
FIXED_CONF="/config/nginx/meet.conf.fixed"

echo "[Protect Config] Final verification of meet.conf..."

# Wait for meet.conf to exist
for i in {1..40}; do
    if [ -f "$MEET_CONF" ]; then
        break
    fi
    sleep 1
done

if [ ! -f "$MEET_CONF" ]; then
    echo "[Protect Config] WARNING: meet.conf not found after 40 seconds"
    exit 0
fi

# Check if file has our fixed BOSH configuration
if ! grep -q 'proxy_pass http://prosody:5280/http-bind;' "$MEET_CONF"; then
    echo "[Protect Config] ⚠️  meet.conf is still wrong after restore - will be fixed by start-jitsi.sh"
else
    echo "[Protect Config] ✅ meet.conf has our fixed configuration"
    
    # Create a backup of our fixed version for future restores
    cp "$MEET_CONF" "$FIXED_CONF" 2>/dev/null || true
fi

# Make file read-only (may not work if container runs as root)
chmod 444 "$MEET_CONF" 2>/dev/null || true

# Test nginx config
if nginx -t >/dev/null 2>&1; then
    echo "[Protect Config] ✅ Nginx configuration is valid"
    nginx -s reload 2>/dev/null || true
else
    echo "[Protect Config] ⚠️  Nginx configuration test failed"
    nginx -t 2>&1 | head -5
fi

