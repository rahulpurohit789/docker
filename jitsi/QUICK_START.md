# Quick Start Guide

## For Local Testing (Development)

### 1. Setup
```bash
cd docker/jitsi
cp env.example .env
```

### 2. Edit `.env`
```bash
ENVIRONMENT=development
```

### 3. Generate Passwords
```bash
chmod +x generate-passwords.sh
./generate-passwords.sh
```

### 4. Start
```bash
chmod +x start-jitsi.sh
./start-jitsi.sh
```

### 5. Test
Open: `http://localhost`

---

## For Production (EC2)

### 1. Setup on EC2
```bash
cd ~/docker/jitsi
cp env.example .env
```

### 2. Edit `.env`
```bash
ENVIRONMENT=production
PROD_JITSI_DOMAIN=35.154.130.125  # Your EC2 IP
PROD_DOCKER_HOST_ADDRESS=35.154.130.125  # Your EC2 IP
```

### 3. Generate Passwords
```bash
chmod +x generate-passwords.sh
./generate-passwords.sh
```

### 4. Start
```bash
chmod +x start-jitsi.sh
./start-jitsi.sh
```

### 5. Test
Open: `http://35.154.130.125` (your EC2 IP)

---

## Switch Environments

Just change `ENVIRONMENT` in `.env`:

**For Development:**
```bash
ENVIRONMENT=development
```

**For Production:**
```bash
ENVIRONMENT=production
```

Then run:
```bash
./start-jitsi.sh
```

The script automatically configures everything based on the environment!

---

## Common Commands

```bash
# Start
./start-jitsi.sh

# Stop
docker-compose down

# Restart
docker-compose restart

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

---

## Troubleshooting

### Port Already in Use (Local)
Edit `.env`:
```bash
HTTP_PORT=8080
HTTPS_PORT=8443
```
Then access: `http://localhost:8080`

### 502 Error
```bash
./diagnose-and-fix-502.sh
docker-compose restart prosody
```

### WebSocket Issues
```bash
docker-compose restart jvb
```

