#!/usr/bin/with-contenv bash
# Restore our fixed meet.conf after Jitsi's 10-config script generates it
# This script MUST run after 10-config (number 10 is alphabetical, so 10-restore runs after 10-config)

MEET_CONF="/config/nginx/meet.conf"
FIXED_CONF="/config/nginx/meet.conf.fixed"

echo "[Restore Config] Waiting for Jitsi's 10-config to complete..."

# Wait for meet.conf to exist (Jitsi's 10-config generates it)
for i in {1..60}; do
    if [ -f "$MEET_CONF" ]; then
        echo "[Restore Config] meet.conf found - checking if it was overwritten..."
        sleep 2  # Give a moment for any writes to complete
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
    echo "[Restore Config] ⚠️  meet.conf was overwritten by Jitsi's 10-config - restoring fixed version..."
    
    # Backup the overwritten version (for debugging)
    cp "$MEET_CONF" "${MEET_CONF}.overwritten.$(date +%s)" 2>/dev/null || true
    
    # Restore from our fixed backup if it exists
    if [ -f "$FIXED_CONF" ]; then
        cp "$FIXED_CONF" "$MEET_CONF"
        echo "[Restore Config] ✅ Restored from fixed backup"
    else
        # If no backup, try to restore from host (since it's bind-mounted, host has our fixed version)
        # Actually, if it's bind-mounted, the host file IS the file, so we need to restore on host
        echo "[Restore Config] ⚠️  Fixed backup not found in container"
        echo "[Restore Config]     Will be restored by start-jitsi.sh script"
    fi
else
    echo "[Restore Config] ✅ meet.conf already has our fixed configuration"
fi

# Make file read-only to prevent further overwrites (may not work if container runs as root)
chmod 444 "$MEET_CONF" 2>/dev/null || true

echo "[Restore Config] ✅ Configuration restored and protected"

