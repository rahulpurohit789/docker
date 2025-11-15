#!/usr/bin/with-contenv bash
# Protect meet.conf from being overwritten by making it read-only
# This script runs after 10-config generates meet.conf

MEET_CONF="/config/nginx/meet.conf"

echo "[Protect Config] Waiting for meet.conf..."

# Wait for meet.conf to exist (Jitsi's 10-config may generate it)
for i in {1..40}; do
    if [ -f "$MEET_CONF" ]; then
        echo "[Protect Config] meet.conf found"
        sleep 2  # Give a moment for any writes to complete
        break
    fi
    sleep 1
done

if [ ! -f "$MEET_CONF" ]; then
    echo "[Protect Config] WARNING: meet.conf not found after 40 seconds"
    exit 0  # Don't fail, just continue
fi

# Make file read-only to prevent Jitsi from overwriting it on restart
chmod 444 "$MEET_CONF"

echo "[Protect Config] ✅ meet.conf is now protected (read-only)"

