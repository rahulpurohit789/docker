# BOSH Configuration Fix

The Jitsi web container generates `meet.conf` with an incorrect BOSH endpoint on every startup. This document explains how to fix it.

## Problem

The generated `meet.conf` has:
```nginx
location = /http-bind {
    proxy_set_header Host localhost;
    proxy_pass http://localhost/http-bind/http-bind;  # ❌ WRONG
}
```

This should be:
```nginx
location = /http-bind {
    proxy_set_header Host $http_host;
    proxy_pass http://prosody:5280/http-bind;  # ✅ CORRECT
}
```

## Automatic Fix Script

A fix script is located at `/config/99-fix-bosh.sh` inside the container. 

### Option 1: Run Manually After Container Starts

After starting containers, run:

```bash
cd docker/jitsi
docker-compose exec web /config/99-fix-bosh.sh
```

### Option 2: Add to Startup (Recommended)

Create a wrapper script or add to your docker-compose.override.yml:

```yaml
services:
  web:
    entrypoint: /bin/bash
    command: -c "sleep 10 && /config/99-fix-bosh.sh && exec /init"
```

**Note:** This requires knowing the original entrypoint, which may vary by Jitsi version.

### Option 3: Use a Post-Start Script

Create `docker/jitsi/post-start.sh`:

```bash
#!/bin/bash
cd "$(dirname "$0")"
docker-compose up -d
sleep 5
docker-compose exec web /config/99-fix-bosh.sh
echo "BOSH configuration fixed!"
```

Then run `./post-start.sh` instead of `docker-compose up -d`.

## Verify Fix

Check that the configuration is correct:

```bash
docker-compose exec web grep -A 8 'location = /http-bind' /config/nginx/meet.conf
```

You should see:
```nginx
location = /http-bind {
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Proto $scheme;

    proxy_pass http://prosody:5280/http-bind;
    ...
}
```

## Why This Happens

Jitsi's `10-config` script generates `meet.conf` from a template on every container startup. The template has the incorrect BOSH configuration hardcoded. The fix script runs after `10-config` completes and replaces the incorrect block with the correct one.

