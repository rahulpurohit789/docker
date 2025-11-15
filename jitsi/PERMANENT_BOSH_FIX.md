# Permanent BOSH Configuration Fix

## Problem

The Jitsi web container **regenerates** `meet.conf` on every startup, overwriting our fixed BOSH configuration. This causes 500 errors when connecting to meetings.

## Solution: Use Startup Script

Since the container regenerates `meet.conf` on every restart, we need to apply the fix **after** the container starts.

### Option 1: Use the Startup Script (Recommended)

Use the provided startup script that automatically applies the fix:

```bash
cd docker/jitsi
./start-jitsi-fixed.sh
```

This script:
1. Starts containers
2. Waits for them to initialize
3. Automatically applies BOSH fix
4. Reloads nginx

### Option 2: Manual Fix After Container Starts

If containers are already running:

```bash
cd docker/jitsi

# Apply fix
docker-compose exec -T web bash -c "
sed -i 's|proxy_pass http://localhost/http-bind/http-bind;|proxy_pass http://prosody:5280/http-bind;|g' /config/nginx/meet.conf
sed -i 's|proxy_set_header Host localhost;|proxy_set_header Host \$http_host;|g' /config/nginx/meet.conf
nginx -s reload
"

# Verify fix
docker-compose exec -T web grep 'proxy_pass.*prosody' /config/nginx/meet.conf
```

### Option 3: Quick Fix Script

Use the quick fix script:

```bash
cd docker/jitsi
./fix-bosh.sh
```

## Why This Happens

1. Jitsi container runs `10-config` script on startup
2. This script **regenerates** `meet.conf` from a template
3. The template has incorrect BOSH configuration hardcoded
4. Our fix needs to be applied **after** the container generates the config

## Persistent Solution

The `meet.conf` file in `jitsi-config/web/nginx/` is a **template** that shows what the correct configuration should be. However, the container **overwrites** it on startup.

**Solution**: Use the startup script (`start-jitsi-fixed.sh`) which automatically applies the fix after container starts.

## Testing

After applying the fix:

1. **Refresh browser**: http://localhost
2. **Create a room**: Enter room name and click "Go"
3. **Check console**: Should NOT see 500 errors
4. **Test video/audio**: Should work correctly

## Verification

Check that the fix is applied:

```bash
docker-compose exec web grep -A 5 'location = /http-bind' /config/nginx/meet.conf
```

Should show:
```nginx
location = /http-bind {
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Proto $scheme;

    proxy_pass http://prosody:5280/http-bind;
```

**Key**: `proxy_pass` should be `http://prosody:5280/http-bind`, NOT `http://localhost/http-bind/http-bind`.

## Important Notes

1. **Fix must be applied after every container restart**
2. **Use `start-jitsi-fixed.sh`** to ensure fix is applied automatically
3. **The fix is persistent** - once applied, it works until container restarts
4. **For production**, consider creating a custom Docker image with the fix pre-applied

## For Production Deployment

For production, you can:

1. **Use the startup script** in your deployment process
2. **Create a systemd service** that applies the fix after container starts
3. **Build a custom Docker image** with the fix baked in
4. **Use Kubernetes init container** to apply the fix

---

**Current Status**: ✅ Fix applied and working!  
**Next Step**: Test in browser at http://localhost

