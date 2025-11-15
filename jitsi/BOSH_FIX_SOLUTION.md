# BOSH Configuration Fix - Complete Solution

## Problem

The Jitsi web container generates `meet.conf` with an incorrect BOSH endpoint on every startup:
- ❌ **Wrong**: `proxy_pass http://localhost/http-bind/http-bind;` (double path, wrong host)
- ✅ **Correct**: `proxy_pass http://prosody:5280/http-bind;` (correct service, correct port)

This causes 500 errors when trying to connect to Jitsi meetings.

## Solution: Automatic Fix on Container Start

The fix needs to be applied every time the container starts because Jitsi regenerates the config.

### Option 1: Use the Fix Script After Container Starts (Current Solution)

After starting containers, run:

```bash
cd docker/jitsi
docker-compose exec -T web bash -c "bash /config/99-fix-bosh.sh && nginx -s reload"
```

Or use the provided `start-jitsi.sh` script:

```bash
cd docker/jitsi
chmod +x start-jitsi.sh
./start-jitsi.sh
```

### Option 2: Create a Wrapper Script (Recommended for Production)

Create a script that starts containers and automatically applies the fix:

```bash
#!/bin/bash
cd "$(dirname "$0")"

echo "Starting Jitsi containers..."
docker-compose up -d

echo "Waiting for containers to initialize..."
sleep 10

echo "Applying BOSH configuration fix..."
docker-compose exec -T web bash -c "bash /config/99-fix-bosh.sh && nginx -s reload"

echo "✅ Jitsi is ready!"
```

### Option 3: Modify docker-compose.yml (Advanced)

Add a healthcheck and fix script to docker-compose.yml:

```yaml
services:
  web:
    # ... existing config ...
    healthcheck:
      test: ["CMD", "bash", "-c", "bash /config/99-fix-bosh.sh && nginx -t"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## Quick Fix Command

If you're already running and getting 500 errors:

```bash
cd docker/jitsi
docker-compose exec -T web bash -c "bash /config/99-fix-bosh.sh && nginx -s reload"
```

Wait 5 seconds, then refresh your browser.

## Verify Fix

Check that the configuration is correct:

```bash
docker-compose exec -T web bash -c "grep -A 5 'location = /http-bind' /config/nginx/meet.conf"
```

You should see:
```nginx
location = /http-bind {
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Proto $scheme;

    proxy_pass http://prosody:5280/http-bind;
```

**Key**: The `proxy_pass` should point to `http://prosody:5280/http-bind`, NOT `http://localhost/http-bind/http-bind`.

## Why This Happens

1. Jitsi web container runs `10-config` script on startup
2. This script generates `meet.conf` from a template
3. The template has the incorrect BOSH configuration hardcoded
4. The `99-fix-bosh.sh` script runs after `10-config` and fixes it
5. However, if the container restarts, the fix is lost and needs to be reapplied

## Permanent Solution (For Production)

For production deployments, consider:

1. **Using a custom entrypoint script** that runs the fix automatically
2. **Building a custom Docker image** with the fix pre-applied
3. **Using environment variables** that the Jitsi container respects (if available in future versions)

## Testing

After applying the fix:

1. Refresh your browser (http://localhost)
2. Create a new room
3. Check browser console - you should NOT see 500 errors
4. Video/audio should work correctly

---

**Note**: This fix needs to be applied every time the web container restarts or is recreated.

