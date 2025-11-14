# Jitsi Meet Docker Setup

Complete Docker setup for self-hosted Jitsi Meet integration with CollabSphere.

## Quick Start

### 1. Initial Setup

```bash
# Navigate to Jitsi directory
cd docker/jitsi

# Copy environment file
cp .env.example .env

# Edit .env with your settings
# IMPORTANT: Set JWT_APP_SECRET to match your backend JITSI_SECRET
```

### 2. Generate Passwords (First Time Only)

**Linux/Mac:**
```bash
chmod +x generate-passwords.sh
./generate-passwords.sh
```

**Windows (PowerShell):**
```powershell
# Generate passwords manually and add to .env
# Or use Git Bash to run generate-passwords.sh
```

### 3. Start Jitsi Meet

```bash
docker-compose up -d
```

### 4. Check Logs

```bash
docker-compose logs -f
```

### 5. Stop Jitsi Meet

```bash
docker-compose down
```

## Configuration

### Development Setup (localhost)

For local development, set in `.env`:
- `JITSI_DOMAIN=localhost`
- `DOCKER_HOST_ADDRESS=localhost`
- `ENABLE_LETSENCRYPT=0`

Access at: `http://localhost`

**Backend .env:**
```env
JITSI_DOMAIN=localhost
JITSI_APP_ID=collabsphere
JITSI_SECRET=dev-jitsi-secret-change-in-production
```

**Frontend .env:**
```env
VITE_JITSI_DOMAIN=localhost
```

### Production Setup

1. **Set your domain in `.env`:**
   - `JITSI_DOMAIN=meet.yourdomain.com`
   - `DOCKER_HOST_ADDRESS=your-server-ip`

2. **Point DNS A record to your server IP**

3. **Enable Let's Encrypt:**
   - `ENABLE_LETSENCRYPT=1`
   - `LETSENCRYPT_EMAIL=your-email@example.com`

4. **Open ports in firewall:**
   - 80 (HTTP)
   - 443 (HTTPS)
   - 10000/udp (JVB media)

5. **Backend .env:**
```env
JITSI_DOMAIN=meet.yourdomain.com
JITSI_APP_ID=collabsphere
JITSI_SECRET=your-very-secure-secret-key-change-this-in-production
```

6. **Frontend .env:**
```env
VITE_JITSI_DOMAIN=meet.yourdomain.com
```

## Important Notes

### JWT Secret Matching

**CRITICAL:** The `JWT_APP_SECRET` in Jitsi `.env` **MUST** match `JITSI_SECRET` in your backend `.env` file. Otherwise, authentication will fail.

### Port Requirements

- **HTTP (80)**: Web interface
- **HTTPS (443)**: Secure web interface
- **UDP 10000**: Media traffic (JVB)
- **TCP 4443**: JVB API

### Security

- Never commit `.env` file with real secrets
- Use strong, random passwords
- Enable Let's Encrypt for production
- Keep Docker images updated

## Update Jitsi

```bash
docker-compose pull
docker-compose up -d
```

## Troubleshooting

### Check Service Status
```bash
docker-compose ps
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f web
docker-compose logs -f prosody
docker-compose logs -f jvb
docker-compose logs -f jicofo
```

### Restart Services
```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart web
```

### Clean Restart
```bash
docker-compose down
docker-compose up -d
```

### Common Issues

1. **Can't join meeting:**
   - Check JWT secret matches between Jitsi and backend
   - Verify ports are open
   - Check logs for errors

2. **No audio/video:**
   - Ensure UDP port 10000 is open
   - Check browser permissions
   - Verify STUN servers are accessible

3. **SSL Certificate Issues:**
   - For localhost, disable Let's Encrypt
   - For production, ensure DNS is configured correctly
   - Check Let's Encrypt rate limits

## Architecture

- **web**: Nginx web server serving Jitsi Meet UI
- **prosody**: XMPP server for signaling
- **jvb**: Jitsi Videobridge for media routing
- **jicofo**: Conference focus for room management

## Resources

- [Jitsi Meet Documentation](https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker)
- [JWT Authentication](https://jitsi.github.io/handbook/docs/devops-guide/secure-domain)

