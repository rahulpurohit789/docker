# Test Jitsi Locally - Step by Step Guide

## Prerequisites
- ✅ Docker Desktop installed
- ✅ Docker Desktop **RUNNING** (check system tray)
- ✅ `.env` file configured for localhost

## Step 1: Start Docker Desktop

1. Open Docker Desktop application
2. Wait until you see "Docker Desktop is running"
3. You should see the Docker icon in your system tray

## Step 2: Verify Docker is Running

Open terminal/PowerShell and run:
```bash
docker ps
```

If you see an empty list (no errors), Docker is running! ✅

## Step 3: Navigate to Jitsi Directory

```bash
cd docker/jitsi
```

## Step 4: Check Current Status

```bash
docker-compose ps
```

If Jitsi is already running, you'll see 4 services (web, prosody, jvb, jicofo).

If nothing is running, continue to next step.

## Step 5: Start Jitsi Services

```bash
docker-compose up -d
```

**What this does:**
- Downloads Jitsi Docker images (first time only - may take 2-3 minutes)
- Starts 4 containers: web, prosody, jvb, jicofo
- Runs in background (`-d` flag)

**Expected output:**
```
Creating network "jitsi-meet_jitsi-meet" ... done
Creating jitsi-prosody ... done
Creating jitsi-web ... done
Creating jitsi-jvb ... done
Creating jitsi-jicofo ... done
```

## Step 6: Wait for Services to Start

Wait 30-60 seconds for all services to fully initialize.

## Step 7: Verify Services are Running

```bash
docker-compose ps
```

**You should see all 4 services with "Up" status:**
```
NAME            STATUS          PORTS
jitsi-jicofo    Up (healthy)
jitsi-jvb       Up              0.0.0.0:10000->10000/udp, 0.0.0.0:4443->4443/tcp
jitsi-prosody   Up              0.0.0.0:5280->5280/tcp
jitsi-web       Up              0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
```

## Step 8: Check Logs (Optional)

```bash
# View logs for all services
docker-compose logs --tail=50

# View logs for specific service
docker-compose logs web --tail=30

# Follow logs in real-time
docker-compose logs -f
```

Press `Ctrl+C` to exit logs.

## Step 9: Test in Browser

1. Open your web browser
2. Navigate to: **http://localhost**
3. You should see the Jitsi Meet interface ✅

## Step 10: Create Test Room

1. Enter a room name (e.g., `test-room-123`)
2. Click "Go" or press Enter
3. Allow camera/microphone permissions when prompted
4. You should see your video feed! ✅

## Step 11: Test from Another Browser/Device (Optional)

1. Open another browser or device
2. Navigate to: **http://localhost** (or http://your-local-ip if testing from another device on same network)
3. Join the same room name (`test-room-123`)
4. Both participants should see and hear each other ✅

## Troubleshooting

### Issue: "Docker Desktop is not running"

**Solution:**
1. Open Docker Desktop application
2. Wait for it to fully start
3. Check system tray for Docker icon

### Issue: Port 80 already in use

**Solution:**
1. Check what's using port 80:
   ```bash
   netstat -ano | findstr :80
   ```
2. Stop the service using port 80 (like IIS or another web server)
3. Or change HTTP_PORT in `.env` file to a different port (e.g., 8080)

### Issue: Containers won't start

**Solution:**
```bash
# Check logs for errors
docker-compose logs

# Try stopping and restarting
docker-compose down
docker-compose up -d
```

### Issue: Can't access http://localhost

**Solution:**
1. Verify containers are running: `docker-compose ps`
2. Check web container logs: `docker-compose logs web`
3. Try: `curl http://localhost` (from terminal)

### Issue: No audio/video

**Solution:**
1. Check browser permissions (allow camera/microphone)
2. Check JVB logs: `docker-compose logs jvb`
3. Verify firewall allows UDP port 10000

## Useful Commands

```bash
# Stop Jitsi
docker-compose down

# Start Jitsi
docker-compose up -d

# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart web

# View resource usage
docker stats

# Remove everything (clean start)
docker-compose down -v
```

## Success Checklist

- [ ] Docker Desktop is running
- [ ] `docker ps` works without errors
- [ ] All 4 Jitsi containers are running (`docker-compose ps`)
- [ ] Can access http://localhost in browser
- [ ] Can create a room and see video feed
- [ ] Audio/video working correctly

## Next Steps

Once local testing works:
1. Test with your backend (ensure JITSI_SECRET matches)
2. Test with your frontend (ensure VITE_JITSI_DOMAIN=localhost)
3. Deploy to EC2 using the same process

---

**Happy Testing! 🚀**

