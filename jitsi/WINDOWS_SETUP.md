# Windows Setup Guide for Jitsi Docker

## Step 1: Generate Passwords

You have **3 options** to generate passwords:

### Option A: Use PowerShell Script (Recommended)

1. Open PowerShell in the `docker/jitsi` directory
2. Run:
   ```powershell
   .\generate-passwords.ps1
   ```

### Option B: Use Git Bash (If you have Git installed)

1. Open Git Bash in the `docker/jitsi` directory
2. Run:
   ```bash
   chmod +x generate-passwords.sh
   ./generate-passwords.sh
   ```

### Option C: Generate Manually

1. Open PowerShell
2. Run these commands one by one:

```powershell
# Generate JVB password
[Convert]::ToHexString((1..16 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 })).ToLower()

# Generate Jicofo password
[Convert]::ToHexString((1..16 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 })).ToLower()

# Generate Jibri Recorder password
[Convert]::ToHexString((1..16 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 })).ToLower()

# Generate Jibri XMPP password
[Convert]::ToHexString((1..16 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 })).ToLower()
```

3. Copy each generated password
4. Add them to your `.env` file:
   ```
   JVB_AUTH_PASSWORD=<paste-first-password>
   JICOFO_AUTH_PASSWORD=<paste-second-password>
   JIBRI_RECORDER_PASSWORD=<paste-third-password>
   JIBRI_XMPP_PASSWORD=<paste-fourth-password>
   ```

---

## Step 2: Start Docker

### Prerequisites

1. **Install Docker Desktop for Windows** (if not installed):
   - Download from: https://www.docker.com/products/docker-desktop
   - Install and restart your computer
   - Make sure Docker Desktop is running (you'll see the Docker icon in system tray)

### Start Jitsi Docker Containers

1. **Open PowerShell or Command Prompt**

2. **Navigate to the Jitsi directory:**
   ```powershell
   cd C:\Users\ASUS\OneDrive\Desktop\collabesphere\docker\jitsi
   ```

3. **Start Docker containers:**
   ```powershell
   docker-compose up -d
   ```

   **What this does:**
   - `docker-compose` - Runs Docker Compose
   - `up` - Starts the containers
   - `-d` - Runs in background (detached mode)

4. **Verify containers are running:**
   ```powershell
   docker-compose ps
   ```

   You should see 4 services running:
   - `jitsi-web-1` (or similar name)
   - `jitsi-prosody-1`
   - `jitsi-jvb-1`
   - `jitsi-jicofo-1`

---

## Troubleshooting

### Issue: "docker-compose: command not found"

**Solution:**
- Make sure Docker Desktop is installed and running
- Try using `docker compose` (without hyphen) instead:
  ```powershell
  docker compose up -d
  ```

### Issue: "Cannot connect to Docker daemon"

**Solution:**
- Open Docker Desktop application
- Wait for it to fully start (whale icon in system tray)
- Try again

### Issue: Port already in use

**Solution:**
- Port 80 or 443 might be in use
- Change ports in `.env` file:
  ```
  HTTP_PORT=8080
  HTTPS_PORT=8443
  ```

### Issue: Containers keep restarting

**Solution:**
- Check logs:
  ```powershell
  docker-compose logs
  ```
- Make sure all passwords are set in `.env` file
- Verify `JWT_APP_SECRET` matches backend `JITSI_SECRET`

---

## Useful Commands

### View Logs
```powershell
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f web
docker-compose logs -f prosody
```

### Stop Containers
```powershell
docker-compose down
```

### Restart Containers
```powershell
docker-compose restart
```

### Check Container Status
```powershell
docker-compose ps
```

### View Container Details
```powershell
docker ps
```

---

## Quick Start Checklist

- [ ] Docker Desktop installed and running
- [ ] `.env` file created in `docker/jitsi/` directory
- [ ] Passwords generated and added to `.env`
- [ ] `JWT_APP_SECRET` matches backend `JITSI_SECRET`
- [ ] Run `docker-compose up -d`
- [ ] Verify with `docker-compose ps` (should see 4 services)
- [ ] Check logs if issues: `docker-compose logs`

---

## Next Steps

After Docker is running:
1. Start your backend: `cd collabsphere-backend && npm run dev`
2. Start your frontend: `cd collabsphere-client && npm run dev`
3. Test the integration!

