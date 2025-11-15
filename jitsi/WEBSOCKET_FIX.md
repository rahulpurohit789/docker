# JVB WebSocket Configuration Fix

## Problem

The Jitsi Videobridge (JVB) container regenerates `jvb.conf` on every restart, hardcoding:
- `domain = "localhost:8443"` (should be your EC2 IP:4443)
- `tls = true` (should be false for HTTP)
- `public-address = "localhost"` (should be your EC2 IP)

This causes WebSocket connection failures: `wss://localhost:8443/colibri-ws/...` fails.

## Solution

### Option 1: Use the Fix Script (Recommended)

After starting containers, run:

```bash
cd ~/docker/jitsi
./fix-jvb-websocket.sh
```

This script:
1. Updates `jvb.conf` with correct IP address
2. Disables TLS (for HTTP deployments)
3. Updates static mapping
4. Restarts JVB container

### Option 2: Use the Startup Script (Automatic)

Use `start-jitsi-fixed.sh` which applies both BOSH and JVB fixes automatically:

```bash
cd ~/docker/jitsi
./start-jitsi-fixed.sh
```

### Option 3: Manual Fix

```bash
cd ~/docker/jitsi

# Fix websocket domain (replace with your IP)
sed -i 's/domain = "localhost:8443"/domain = "35.154.130.125:4443"/g' jitsi-config/jvb/jvb.conf

# Fix TLS
sed -i 's/tls = true/tls = false/g' jitsi-config/jvb/jvb.conf

# Fix public address
sed -i 's/public-address = "localhost"/public-address = "35.154.130.125"/g' jitsi-config/jvb/jvb.conf

# Restart
docker-compose restart jvb
```

## Configuration

The scripts use these environment variables from `.env`:

- `JITSI_DOMAIN` - Your Jitsi domain (IP or domain name)
- `DOCKER_HOST_ADDRESS` - Your server IP address

If using IP address, both should be set to your EC2 IP (e.g., `35.154.130.125`).

## Important Notes

1. **Port**: JVB uses port `4443` for TCP/WebSocket, not `8443`
2. **TLS**: Set to `false` when using HTTP (not HTTPS)
3. **Persistent Fix**: The fix must be applied after every container restart since JVB regenerates the config
4. **Security Group**: Ensure port `4443/tcp` is open in AWS Security Group

## Verify Fix

```bash
# Check websocket configuration
cat jitsi-config/jvb/jvb.conf | grep -A 5 "websockets"

# Should show:
# domain = "35.154.130.125:4443"
# tls = false

# Check JVB logs
docker-compose logs jvb | grep -E "websocket|35.154|static.*mapping" | tail -10
```

## When to Apply

- After every `docker-compose restart jvb`
- After every `docker-compose restart`
- After every `docker-compose down && docker-compose up -d`

**Recommended**: Always use `start-jitsi-fixed.sh` to ensure fixes are applied automatically.

