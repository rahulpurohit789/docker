#!/usr/bin/with-contenv bash
# Restore our fixed meet.conf after Jitsi's 10-config script generates it
# This script runs after 10-config (number 20 ensures it runs after 10-*)

MEET_CONF="/config/nginx/meet.conf"
FIXED_CONF="/config/nginx/meet.conf.fixed"

echo "[Restore Config] Starting - will restore fixed meet.conf after Jitsi generates it..."

# Wait for meet.conf to exist (Jitsi's 10-config generates it)
for i in {1..60}; do
    if [ -f "$MEET_CONF" ]; then
        echo "[Restore Config] meet.conf found"
        sleep 3  # Give Jitsi's script time to finish writing
        break
    fi
    sleep 1
done

if [ ! -f "$MEET_CONF" ]; then
    echo "[Restore Config] WARNING: meet.conf not found after 60 seconds"
    exit 0  # Don't fail, just continue
fi

# Check if file has our fixed BOSH configuration
if ! grep -q 'proxy_pass http://prosody:5280/http-bind;' "$MEET_CONF"; then
    echo "[Restore Config] ⚠️  meet.conf was overwritten by Jitsi's 10-config"
    
    # Backup the overwritten version (for debugging)
    cp "$MEET_CONF" "${MEET_CONF}.overwritten.$(date +%s)" 2>/dev/null || true
    
    # Restore from our fixed backup (created by start-jitsi.sh on host, then copied to container via bind mount)
    if [ -f "$FIXED_CONF" ]; then
        echo "[Restore Config] Restoring from fixed backup..."
        chmod 644 "$MEET_CONF" 2>/dev/null || true
        cp "$FIXED_CONF" "$MEET_CONF"
        echo "[Restore Config] ✅ Restored from fixed backup"
    else
        echo "[Restore Config] ⚠️  Fixed backup not found in container"
        echo "[Restore Config]     Will be restored by host script (start-jitsi.sh)"
    fi
else
    echo "[Restore Config] ✅ meet.conf already has our fixed configuration"
    
    # Create backup for future use
    cp "$MEET_CONF" "$FIXED_CONF" 2>/dev/null || true
fi

# Make file read-only to prevent further overwrites (may not work if container runs as root)
chmod 444 "$MEET_CONF" 2>/dev/null || true

echo "[Restore Config] ✅ Configuration restore completed"

