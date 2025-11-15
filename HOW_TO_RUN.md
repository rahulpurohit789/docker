# 🐳 How to Run Docker for CollabSphere

Complete step-by-step guide to run all Docker services.

## 📋 Prerequisites

1. **Docker Desktop** installed and running
   - Windows/Mac: [Download Docker Desktop](https://www.docker.com/products/docker-desktop)
   - Linux: Install Docker Engine and Docker Compose
   
2. **Verify Docker is running:**
   ```bash
   docker --version
   docker-compose --version
   # Or on newer Docker: docker compose version
   ```

## 🚀 Quick Start (Recommended for Development)

### Step 1: Start Database & Redis

```bash
# Navigate to infra directory
cd infra

# Start PostgreSQL and Redis
docker-compose up -d postgres redis

# Verify they're running
docker-compose ps

# You should see:
# - collabsphere-db (postgres) - Up
# - collabsphere-redis (redis) - Up
```

**Access Database:**
- Host: `localhost`
- Port: `5432`
- User: `postgres`
- Password: `postgres`
- Database: `collabsphere`

### Step 2: Setup Backend (Run Locally)

```bash
# Navigate to server directory
cd server

# Create .env file if it doesn't exist
cat > .env << EOF
NODE_ENV=development
PORT=5000
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=collabsphere
REDIS_ENABLED=true
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_SECRET=dev-secret-change-in-production
JITSI_DOMAIN=localhost
JITSI_APP_ID=collabsphere
JITSI_SECRET=dev-jitsi-secret-change-in-production
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173
EOF

# Install dependencies (first time only)
npm install

# Start backend
npm run dev
```

Backend should start on **http://localhost:5000**

### Step 3: Setup Client (Run Locally)

```bash
# Open a NEW terminal
cd client

# Create .env file if it doesn't exist
cat > .env << EOF
VITE_API_URL=http://localhost:5000/api
VITE_SOCKET_URL=http://localhost:5000
VITE_JITSI_DOMAIN=localhost
EOF

# Install dependencies (first time only)
npm install

# Start client
npm run dev
```

Client should start on **http://localhost:3000**

### Step 4: Setup Jitsi (Docker)

```bash
# Open a NEW terminal
cd docker/jitsi

# Create .env file
cat > .env << EOF
# Domain Configuration
JITSI_DOMAIN=localhost
DOCKER_HOST_ADDRESS=localhost

# Ports
HTTP_PORT=80
HTTPS_PORT=443
JVB_PORT=10000
JVB_TCP_PORT=4443

# JWT Authentication (MUST match backend JITSI_SECRET)
JWT_APP_ID=collabsphere
JWT_APP_SECRET=dev-jitsi-secret-change-in-production

# Let's Encrypt (0 for development)
ENABLE_LETSENCRYPT=0
LETSENCRYPT_EMAIL=your-email@example.com

# Config directory
CONFIG=./jitsi-config

# Passwords (will be generated)
JVB_AUTH_PASSWORD=
JICOFO_AUTH_PASSWORD=
JIBRI_RECORDER_PASSWORD=
JIBRI_XMPP_PASSWORD=
EOF

# Generate passwords
# On Linux/Mac:
chmod +x generate-passwords.sh
./generate-passwords.sh

# On Windows PowerShell:
.\generate-passwords.ps1

# On Windows Git Bash:
chmod +x generate-passwords.sh
./generate-passwords.sh

# Start Jitsi services
docker-compose up -d

# Verify services are running
docker-compose ps

# You should see 4 services:
# - jitsi-web-1 (or similar) - Up
# - jitsi-prosody-1 - Up
# - jitsi-jvb-1 - Up
# - jitsi-jicofo-1 - Up
```

Jitsi should be available at **http://localhost**

## 🎯 Full Docker Setup (All Services in Docker)

If you want to run backend in Docker too:

### Step 1: Setup Environment Files

**Backend** (`server/.env`):
```env
NODE_ENV=production
PORT=5000
DB_HOST=postgres
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=collabsphere
REDIS_HOST=redis
REDIS_PORT=6379
JWT_SECRET=dev-secret-change-in-production
JITSI_DOMAIN=localhost
JITSI_APP_ID=collabsphere
JITSI_SECRET=dev-jitsi-secret-change-in-production
ALLOWED_ORIGINS=http://localhost:3000
```

### Step 2: Start All Services

```bash
cd infra

# Start all services (postgres, redis, backend, ai-service)
docker-compose up -d --build

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# View logs for specific service
docker-compose logs -f backend
docker-compose logs -f postgres
```

### Step 3: Verify Services

```bash
# Check if backend is running
curl http://localhost:5000/health

# Check database connection
docker-compose exec postgres psql -U postgres -d collabsphere -c "SELECT 1;"

# Check Redis
docker-compose exec redis redis-cli ping
```

## 📊 Service Status Check

### Check All Docker Services

```bash
# Main services (infra)
cd infra
docker-compose ps

# Jitsi services
cd docker/jitsi
docker-compose ps

# Or check all Docker containers
docker ps
```

### View Logs

```bash
# Main services logs
cd infra
docker-compose logs -f

# Jitsi logs
cd docker/jitsi
docker-compose logs -f

# Specific service logs
docker-compose logs -f backend
docker-compose logs -f web
docker-compose logs -f prosody
```

## 🛠️ Common Commands

### Start Services

```bash
# Start specific services
docker-compose up -d postgres redis

# Start all services
docker-compose up -d

# Start and rebuild
docker-compose up -d --build
```

### Stop Services

```bash
# Stop services (keeps containers)
docker-compose stop

# Stop and remove containers
docker-compose down

# Stop and remove containers + volumes (⚠️ deletes data)
docker-compose down -v
```

### Restart Services

```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart backend
docker-compose restart web
```

### Update Services

```bash
# Pull latest images
docker-compose pull

# Rebuild and restart
docker-compose up -d --build
```

## 🔍 Troubleshooting

### Port Already in Use

**Problem:** Port 80, 443, or 5432 is already in use

**Solution:**
```bash
# For Jitsi, change ports in docker/jitsi/.env:
HTTP_PORT=8080
HTTPS_PORT=8443

# For PostgreSQL, change in infra/docker-compose.yml:
ports:
  - "5433:5432"  # Change first number

# Restart services
docker-compose down
docker-compose up -d
```

### Docker Containers Won't Start

**Check logs:**
```bash
docker-compose logs
```

**Common issues:**
1. **Missing environment variables**: Check `.env` file exists
2. **Wrong passwords**: Regenerate passwords for Jitsi
3. **Port conflicts**: Change ports or stop conflicting services
4. **Insufficient resources**: Check Docker Desktop settings

### Database Connection Issues

```bash
# Check if PostgreSQL is running
docker-compose ps postgres

# Test connection
docker-compose exec postgres psql -U postgres -c "SELECT 1;"

# Check logs
docker-compose logs postgres
```

### Jitsi Won't Start

**Check JWT secret match:**
```bash
# In docker/jitsi/.env:
JWT_APP_SECRET=dev-jitsi-secret-change-in-production

# In server/.env:
JITSI_SECRET=dev-jitsi-secret-change-in-production

# They MUST match!
```

**Check logs:**
```bash
cd docker/jitsi
docker-compose logs -f

# Check specific service
docker-compose logs -f web
docker-compose logs -f prosody
```

### Services Keep Restarting

**Check logs for errors:**
```bash
docker-compose logs | tail -50
```

**Common causes:**
- Missing environment variables
- Wrong passwords (Jitsi)
- Port conflicts
- Resource constraints

## ✅ Verification Checklist

After starting all services:

- [ ] PostgreSQL is running: `docker-compose ps postgres` (should show "Up")
- [ ] Redis is running: `docker-compose ps redis` (should show "Up")
- [ ] Backend is accessible: `curl http://localhost:5000/health` (should return OK)
- [ ] Client is accessible: Open `http://localhost:3000` in browser
- [ ] Jitsi is accessible: Open `http://localhost` in browser (should show Jitsi)
- [ ] All 4 Jitsi services are running: `docker-compose ps` (should show 4 services)

## 🎯 Quick Reference

### Development Workflow

```bash
# Terminal 1: Database & Redis
cd infra
docker-compose up -d postgres redis

# Terminal 2: Backend
cd server
npm run dev

# Terminal 3: Client
cd client
npm run dev

# Terminal 4: Jitsi
cd docker/jitsi
docker-compose up -d
```

### Access URLs

- **Client**: http://localhost:3000
- **Backend API**: http://localhost:5000
- **API Health**: http://localhost:5000/health
- **Jitsi Meet**: http://localhost
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

### Useful Docker Commands

```bash
# View all running containers
docker ps

# View all containers (including stopped)
docker ps -a

# View container logs
docker logs <container-name>

# Execute command in container
docker exec -it <container-name> sh

# Remove all stopped containers
docker container prune

# Remove unused images
docker image prune

# View Docker disk usage
docker system df
```

## 🔒 Security Notes

1. **Never commit `.env` files** - They contain sensitive information
2. **Change default passwords** in production
3. **Use strong secrets** for JWT and Jitsi
4. **Enable HTTPS** in production (Let's Encrypt)
5. **Keep Docker images updated**: `docker-compose pull`

## 📚 Next Steps

1. ✅ All services running
2. ✅ Create a user account (via client)
3. ✅ Create a meeting
4. ✅ Test Jitsi integration
5. ✅ Test chat functionality

---

**Need Help?** Check the logs first: `docker-compose logs -f`

