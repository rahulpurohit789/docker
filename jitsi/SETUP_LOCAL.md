# Local Development Setup

Quick guide to set up Jitsi locally for testing.

## Step 1: Create Environment File

```bash
cd docker/jitsi

# Copy example file
cp env.example .env

# Edit .env - set to development
nano .env
```

In `.env`, set:
```bash
ENVIRONMENT=development
DEV_JITSI_DOMAIN=localhost
DEV_DOCKER_HOST_ADDRESS=localhost
```

## Step 2: Generate Passwords (First Time Only)

```bash
chmod +x generate-passwords.sh
./generate-passwords.sh
```

This will create passwords and update your `.env` file.

## Step 3: Start Jitsi

```bash
chmod +x start-jitsi.sh
./start-jitsi.sh
```

Wait for all containers to start. You should see:
```
✅ Environment: DEVELOPMENT
✅ BOSH configuration fixed
✅ JVB WebSocket configuration updated
✅ Jitsi is ready!
```

## Step 4: Test

Open in browser:
```
http://localhost
```

You should be able to:
- Create a meeting room
- Join a meeting
- See video/audio (if permissions granted)

## Verify Everything Works

```bash
# Check container status
docker-compose ps

# All containers should show "Up" status
```

## Stop Jitsi

```bash
docker-compose down
```

## Restart Jitsi

```bash
./start-jitsi.sh
```

## Troubleshooting

### Port Already in Use

If port 80 or 443 is already in use:

Edit `.env` and change:
```bash
HTTP_PORT=8080
HTTPS_PORT=8443
```

Then access at: `http://localhost:8080`

### Containers Not Starting

```bash
# Check logs
docker-compose logs

# Restart all containers
docker-compose restart
```

### BOSH Connection Errors

The `start-jitsi.sh` script automatically fixes this. If errors persist:

```bash
# Check if Prosody is running
docker-compose ps prosody

# Restart Prosody
docker-compose restart prosody
```

## Next Steps

Once local testing works:
1. Test creating and joining meetings
2. Test with multiple browser tabs
3. Verify audio/video works
4. Switch to production mode when ready (see README.md)

