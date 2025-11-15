# BOSH Configuration Fix - Persistent Solution

## Problem

The Jitsi web container **regenerates** `meet.conf` on every startup from a template. The generated config has an incorrect BOSH endpoint:
- ❌ **Wrong**: `proxy_pass http://localhost/http-bind/http-bind;` (double path, wrong host)
- ✅ **Correct**: `proxy_pass http://prosody:5280/http-bind;` (correct service, correct port)

This causes **500 errors** when trying to connect to Jitsi meetings.

## Solution

We've implemented a **persistent fix** that automatically applies on every container startup:

### 1. Fixed `meet.conf` Template

Location: `docker/jitsi/jitsi-config/web/nginx/meet.conf`

This file contains the **correct BOSH configuration**:
- Main BOSH location: `location = /http-bind` → proxies to `http://prosody:5280/http-bind`
- Subdomain BOSH location: `location ~ ^/([^/?&:'"]+)/http-bind` → proxies directly (no rewrite)

### 2. Automatic Fix Script

Location: `docker/jitsi/jitsi-config/web/99-fix-bosh.sh`

This script **automatically runs** on container startup (after `10-config` generates meet.conf):
- Waits for meet.conf to be generated
- Fixes incorrect BOSH configurations using sed/perl
- Replaces wrong `proxy_pass` with correct one
- Fixes subdomain BOSH rewrites
- Verifies the fix and tests nginx configuration

### 3. How It Works

1. Container starts
2. `10-config` script generates `meet.conf` (with wrong BOSH config)
3. `99-fix-bosh.sh` script runs automatically (fixes BOSH config)
4. Nginx starts with correct configuration

## Files Modified

### `docker/jitsi/jitsi-config/web/nginx/meet.conf`
- **Fixed** BOSH location blocks
- **Persistent** - This file is mounted as a volume, so changes persist

### `docker/jitsi/jitsi-config/web/99-fix-bosh.sh`
- **Automatic fix script** that runs on container startup
- **Executable** - Must have execute permissions
- **Self-healing** - Fixes config even if container regenerates it

## Verification

After container restart, verify the fix:

```bash
# Check if BOSH configuration is correct
docker-compose exec web grep -A 5 'location = /http-bind' /config/nginx/meet.conf

# Should show:
# location = /http-bind {
#     proxy_set_header X-Forwarded-For $remote_addr;
#     proxy_set_header Host $http_host;
#     proxy_set_header X-Forwarded-Proto $scheme;
#
#     proxy_pass http://prosody:5280/http-bind;
```

## Manual Fix (If Needed)

If the automatic fix doesn't work, you can manually apply it:

```bash
cd docker/jitsi
docker-compose exec web bash /config/99-fix-bosh.sh
docker-compose restart web
```

## Testing

1. **Start containers:**
   ```bash
   cd docker/jitsi
   docker-compose up -d
   ```

2. **Wait for containers to start** (30 seconds)

3. **Verify fix:**
   ```bash
   docker-compose exec web grep 'proxy_pass.*prosody' /config/nginx/meet.conf
   ```

4. **Test in browser:**
   - Open: http://localhost
   - Create a room
   - Check browser console - should NOT see 500 errors
   - Video/audio should work

## Important Notes

1. **The fix is persistent** - Our fixed `meet.conf` is in the volume mount
2. **The fix script runs automatically** - No manual intervention needed
3. **Works on container restart** - Fix is reapplied automatically
4. **Subdomain BOSH is fixed** - Room-specific BOSH endpoints work correctly

## Troubleshooting

### Fix script not running?

Check if script is executable:
```bash
ls -la docker/jitsi/jitsi-config/web/99-fix-bosh.sh
chmod +x docker/jitsi/jitsi-config/web/99-fix-bosh.sh
```

### Still getting 500 errors?

1. Check container logs:
   ```bash
   docker-compose logs web | grep -i bosh
   docker-compose logs prosody | grep -i error
   ```

2. Verify BOSH configuration:
   ```bash
   docker-compose exec web cat /config/nginx/meet.conf | grep -A 10 http-bind
   ```

3. Manually apply fix:
   ```bash
   docker-compose exec web bash /config/99-fix-bosh.sh
   docker-compose restart web
   ```

## Summary

✅ **Fixed meet.conf** with correct BOSH configuration  
✅ **Automatic fix script** runs on container startup  
✅ **Persistent** - Changes survive container restarts  
✅ **Subdomain BOSH** fixed (no more double path issues)  

The configuration is now **production-ready** and will work correctly even after container restarts!

