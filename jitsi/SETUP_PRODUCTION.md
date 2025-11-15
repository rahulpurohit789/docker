# Production Setup (EC2)

Quick guide to deploy Jitsi on EC2.

## Step 1: Create Environment File on EC2

```bash
cd ~/docker/jitsi

# Copy example file
cp env.example .env

# Edit .env - set to production
nano .env
```

In `.env`, set:
```bash
ENVIRONMENT=production
PROD_JITSI_DOMAIN=35.154.130.125  # Your EC2 IP
PROD_DOCKER_HOST_ADDRESS=35.154.130.125  # Your EC2 IP
```

**Important:** Replace `35.154.130.125` with your actual EC2 Elastic IP or Public IP.

## Step 2: Generate Passwords (First Time Only)

```bash
chmod +x generate-passwords.sh
./generate-passwords.sh
```

## Step 3: Start Jitsi

```bash
chmod +x start-jitsi.sh
./start-jitsi.sh
```

The script will:
- ✅ Detect production environment
- ✅ Set correct IP addresses
- ✅ Fix BOSH configuration
- ✅ Fix JVB WebSocket configuration (non-TLS for IP)
- ✅ Start all containers

## Step 4: Update Backend

Make sure your backend `.env` has:

```bash
JITSI_DOMAIN=35.154.130.125  # Your EC2 IP
```

Restart your backend server.

## Step 5: Update Frontend

If frontend has hardcoded Jitsi URLs, update them to use the backend API.

## Step 6: Test

Access from browser:
```
http://35.154.130.125  # Your EC2 IP
```

Or use your backend application which should now redirect to the EC2 IP.

## Security Group Settings

Make sure your EC2 Security Group allows:

| Port | Protocol | Source | Description |
|------|----------|--------|-------------|
| 80 | TCP | 0.0.0.0/0 | HTTP |
| 443 | TCP | 0.0.0.0/0 | HTTPS |
| 10000 | UDP | 0.0.0.0/0 | JVB (media) |
| 4443 | TCP | 0.0.0.0/0 | JVB WebSocket |

## Verify Everything Works

```bash
# Check container status
docker-compose ps

# All containers should show "Up" status

# Check logs
docker-compose logs -f
```

## Switch Back to Development

If you need to test locally again:

1. Edit `.env` on your local machine:
   ```bash
   ENVIRONMENT=development
   ```

2. Run:
   ```bash
   ./start-jitsi.sh
   ```

## Troubleshooting

### 502 Bad Gateway

```bash
# Run diagnostics
chmod +x diagnose-and-fix-502.sh
./diagnose-and-fix-502.sh

# Restart Prosody
docker-compose restart prosody
```

### WebSocket Connection Failed

Check JVB configuration:
```bash
docker-compose exec jvb cat /config/jvb.conf | grep -A 5 websockets
```

Should show:
```
domain = "35.154.130.125:4443"
tls = false
```

### Containers Not Accessible

1. Check Security Groups allow traffic
2. Check UFW firewall:
   ```bash
   sudo ufw status
   ```

3. Verify Docker is running:
   ```bash
   docker ps
   ```

## Monitoring

```bash
# View all logs
docker-compose logs -f

# View specific service
docker-compose logs -f web
docker-compose logs -f prosody
docker-compose logs -f jvb
```

## Updates

To update Jitsi:

```bash
# Pull latest images
docker-compose pull

# Restart with new images
docker-compose down
./start-jitsi.sh
```

