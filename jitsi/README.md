# Jitsi Meet Docker Setup

Environment-aware Jitsi Meet deployment for local development and production.

## Quick Start

### Step 1: Setup Environment

```bash
cd docker/jitsi
cp env.example .env
nano .env  # Edit the file
```

**For Local Development:**
```bash
ENVIRONMENT=development
```

**For Production (EC2):**
```bash
ENVIRONMENT=production
PROD_JITSI_DOMAIN=35.154.130.125  # Your EC2 IP
PROD_DOCKER_HOST_ADDRESS=35.154.130.125  # Your EC2 IP
```

### Step 2: Generate Passwords (First Time Only)

```bash
chmod +x generate-passwords.sh
./generate-passwords.sh
```

### Step 3: Start Jitsi

```bash
chmod +x start-jitsi.sh
./start-jitsi.sh
```

That's it! The script automatically:
- ✅ Detects environment (development/production)
- ✅ Sets correct domain and IP addresses
- ✅ Fixes BOSH configuration
- ✅ Fixes JVB WebSocket configuration
- ✅ Starts all containers

## Documentation

- **[QUICK_START.md](QUICK_START.md)** - Quick reference guide
- **[SETUP_LOCAL.md](SETUP_LOCAL.md)** - Detailed local development setup
- **[SETUP_PRODUCTION.md](SETUP_PRODUCTION.md)** - Detailed production setup guide

## File Structure

```
docker/jitsi/
├── README.md                 # This file
├── QUICK_START.md           # Quick reference
├── SETUP_LOCAL.md           # Local setup guide
├── SETUP_PRODUCTION.md      # Production setup guide
├── env.example              # Environment template
├── docker-compose.yml       # Docker Compose configuration
├── setup-env.sh             # Environment setup script
├── start-jitsi.sh           # Main startup script (handles both dev/prod)
├── generate-passwords.sh    # Password generation
├── diagnose-and-fix-502.sh  # Diagnostic tool
└── jitsi-config/            # Configuration files (auto-generated)
```

## Common Commands

```bash
# Start Jitsi
./start-jitsi.sh

# Stop Jitsi
docker-compose down

# Restart Jitsi
docker-compose restart

# View logs
docker-compose logs -f

# Check status
docker-compose ps

# Diagnose issues
./diagnose-and-fix-502.sh
```

## Switching Environments

Simply change `ENVIRONMENT` in `.env`:

**Development:**
```bash
ENVIRONMENT=development
```

**Production:**
```bash
ENVIRONMENT=production
```

Then run `./start-jitsi.sh` again. The script handles everything automatically!

## Troubleshooting

### 502 Bad Gateway on /http-bind

The `start-jitsi.sh` script automatically fixes this. If errors persist:

```bash
# Run diagnostics
./diagnose-and-fix-502.sh

# Restart Prosody
docker-compose restart prosody
```

### WebSocket Connection Failed

```bash
# Restart JVB
docker-compose restart jvb

# Check JVB config
docker-compose exec jvb cat /config/jvb.conf | grep -A 5 websockets
```

### Port Already in Use (Local)

Edit `.env`:
```bash
HTTP_PORT=8080
HTTPS_PORT=8443
```

Then access at: `http://localhost:8080`

## Environment Configuration

The setup uses an environment-aware configuration system:

- **Development Mode**: Uses `localhost`, WebSocket with TLS on `localhost:8443`
- **Production Mode**: Uses EC2 IP, WebSocket without TLS on `IP:4443`

All configuration is handled automatically by `setup-env.sh` and `start-jitsi.sh`.

## Backend Integration

Make sure your backend `.env` matches:

**Development:**
```bash
JITSI_DOMAIN=localhost
```

**Production:**
```bash
JITSI_DOMAIN=35.154.130.125  # Your EC2 IP
```

## Security Notes

- ✅ `.env` file is in `.gitignore` (never commit passwords!)
- ✅ Production passwords are auto-generated
- ✅ Change `JWT_APP_SECRET` in production
- ✅ Use Let's Encrypt for HTTPS in production with domain name

## Support

For issues:
1. Check logs: `docker-compose logs`
2. Run diagnostics: `./diagnose-and-fix-502.sh`
3. Verify environment: `cat .env | grep ENVIRONMENT`
