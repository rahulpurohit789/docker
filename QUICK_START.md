# ⚡ Quick Start - Run Docker in 5 Minutes

Fastest way to get CollabSphere running with Docker.

## 🎯 Quick Setup

### 1️⃣ Start Database & Redis

```bash
cd infra
docker-compose up -d postgres redis
```

✅ Wait for: "Started" messages

### 2️⃣ Setup Backend

```bash
# In a NEW terminal
cd server

# Create .env (copy/paste this):
cat > .env << 'EOF'
NODE_ENV=development
PORT=5000
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=collabsphere
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_SECRET=dev-secret-change-in-production
JITSI_DOMAIN=localhost
JITSI_APP_ID=collabsphere
JITSI_SECRET=dev-jitsi-secret-change-in-production
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173
EOF

# Install & start
npm install
npm run dev
```

✅ Backend running on http://localhost:5000

### 3️⃣ Setup Client

```bash
# In a NEW terminal
cd client

# Create .env (copy/paste this):
cat > .env << 'EOF'
VITE_API_URL=http://localhost:5000/api
VITE_SOCKET_URL=http://localhost:5000
VITE_JITSI_DOMAIN=localhost
EOF

# Install & start
npm install
npm run dev
```

✅ Client running on http://localhost:3000

### 4️⃣ Setup Jitsi

```bash
# In a NEW terminal
cd docker/jitsi

# Create .env (copy/paste this):
cat > .env << 'EOF'
JITSI_DOMAIN=localhost
DOCKER_HOST_ADDRESS=localhost
HTTP_PORT=80
HTTPS_PORT=443
JVB_PORT=10000
JVB_TCP_PORT=4443
JWT_APP_ID=collabsphere
JWT_APP_SECRET=dev-jitsi-secret-change-in-production
ENABLE_LETSENCRYPT=0
CONFIG=./jitsi-config
EOF

# Generate passwords
# Linux/Mac:
chmod +x generate-passwords.sh && ./generate-passwords.sh

# Windows PowerShell:
.\generate-passwords.ps1

# Windows Git Bash:
chmod +x generate-passwords.sh && ./generate-passwords.sh

# Start Jitsi
docker-compose up -d
```

✅ Jitsi running on http://localhost

## 🎉 Done!

**Access your app:**
- **Client**: http://localhost:3000
- **Backend**: http://localhost:5000
- **Jitsi**: http://localhost

## 🔍 Verify Everything Works

```bash
# Check database
cd infra && docker-compose ps

# Check Jitsi
cd docker/jitsi && docker-compose ps

# Check backend
curl http://localhost:5000/health
```

## 🛑 Stop Everything

```bash
# Stop database
cd infra && docker-compose down

# Stop Jitsi
cd docker/jitsi && docker-compose down
```

## ❓ Troubleshooting

**Port 80 in use?**
- Change `HTTP_PORT=8080` in `docker/jitsi/.env`
- Restart: `docker-compose down && docker-compose up -d`

**Backend can't connect to database?**
- Make sure database is running: `cd infra && docker-compose ps`
- Check `.env` file has correct DB_HOST=localhost

**Jitsi won't start?**
- Check passwords are generated: `cat .env | grep PASSWORD`
- Verify JWT_APP_SECRET matches backend JITSI_SECRET

---

**Need more details?** See `docker/HOW_TO_RUN.md`

