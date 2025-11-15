# Jitsi Production Readiness Checklist

## ✅ Pre-Deployment Checklist

### 1. Security Configuration

- [ ] **Strong JWT Secret**: `JWT_APP_SECRET` is a secure random string (32+ characters)
- [ ] **JWT Secret Matching**: `JWT_APP_SECRET` in Jitsi `.env` matches `JITSI_SECRET` in backend `.env`
- [ ] **SSL/HTTPS Enabled**: `ENABLE_LETSENCRYPT=1` for production (requires domain)
- [ ] **Domain Configured**: `JITSI_DOMAIN` set to your production domain
- [ ] **Firewall Configured**: Ports 80, 443, 10000/udp, 4443/tcp are open
- [ ] **Authentication Enabled**: `ENABLE_AUTH=1` (JWT authentication required)

### 2. Environment Configuration

- [ ] **Domain Setup**: DNS A record points to your EC2 Elastic IP
- [ ] **Docker Host Address**: `DOCKER_HOST_ADDRESS` set to your EC2 IP or domain
- [ ] **Public URL**: `PUBLIC_URL` uses HTTPS for production
- [ ] **Passwords Generated**: All Jitsi service passwords are generated and secure

### 3. Code Configuration

- [ ] **BOSH Fix Applied**: `meet.conf` has correct BOSH configuration
- [ ] **Fix Script Ready**: `99-fix-bosh.sh` is in place for automatic fixes
- [ ] **Startup Script**: `start-jitsi-fixed.sh` is ready for deployment

### 4. Backend Integration

- [ ] **Backend .env**: `JITSI_DOMAIN` matches Jitsi domain
- [ ] **Backend .env**: `JITSI_SECRET` matches `JWT_APP_SECRET`
- [ ] **Backend .env**: `JITSI_APP_ID` matches `JWT_APP_ID`
- [ ] **Frontend .env**: `VITE_JITSI_DOMAIN` matches Jitsi domain

### 5. Testing

- [ ] **Local Testing**: Jitsi works locally with authentication
- [ ] **BOSH Connection**: No 500 errors in browser console
- [ ] **Video/Audio**: Can join meetings and see/hear participants
- [ ] **JWT Authentication**: Meetings work when accessed through your application

---

## 🚀 Production Deployment Steps

### Step 1: Update Environment Variables

**On EC2, update `docker/jitsi/.env`:**

```env
# Production Configuration
JITSI_DOMAIN=meet.yourdomain.com
DOCKER_HOST_ADDRESS=your-ec2-elastic-ip
ENABLE_LETSENCRYPT=1
LETSENCRYPT_EMAIL=your-email@example.com
PUBLIC_URL=https://meet.yourdomain.com

# Strong JWT Secret (MUST match backend)
JWT_APP_SECRET=your-very-secure-production-secret-minimum-32-characters
JWT_APP_ID=collabsphere
```

### Step 2: Update Backend Environment

**On your backend server, update `server/.env`:**

```env
# Jitsi Configuration
JITSI_DOMAIN=meet.yourdomain.com
JITSI_APP_ID=collabsphere
JITSI_SECRET=your-very-secure-production-secret-minimum-32-characters
# IMPORTANT: Must match JWT_APP_SECRET in Jitsi .env
```

### Step 3: Update Frontend Environment

**On your frontend, update `client/.env`:**

```env
VITE_JITSI_DOMAIN=meet.yourdomain.com
```

### Step 4: Deploy to EC2

```bash
# On EC2 instance
cd ~/jitsi  # or wherever you uploaded jitsi folder

# Update .env with production values
nano .env

# Start Jitsi with fix script
./start-jitsi-fixed.sh

# Or manually:
docker-compose up -d
sleep 15
docker-compose exec -T web bash -c "bash /config/99-fix-bosh.sh && nginx -s reload"
```

### Step 5: Verify Deployment

1. **Check Services**: `docker-compose ps` (all should be "Up")
2. **Test HTTPS**: `https://meet.yourdomain.com` (should load)
3. **Test from App**: Create meeting in your app and join
4. **Check Logs**: `docker-compose logs web` (no errors)

---

## 🔒 Security Best Practices

1. **Never commit `.env` files** - They contain secrets
2. **Use strong JWT secrets** - Minimum 32 characters, random
3. **Enable HTTPS** - Always use `ENABLE_LETSENCRYPT=1` in production
4. **Restrict Security Groups** - Only open necessary ports
5. **Regular Updates** - Keep Docker images updated: `docker-compose pull`
6. **Monitor Logs** - Check for suspicious activity
7. **Backup Config** - Backup `jitsi-config` directory regularly

---

## 📝 Production Environment Variables Summary

### Jitsi (`docker/jitsi/.env`)
```env
JITSI_DOMAIN=meet.yourdomain.com
DOCKER_HOST_ADDRESS=your-ec2-ip
JWT_APP_SECRET=strong-secret-matching-backend
ENABLE_LETSENCRYPT=1
PUBLIC_URL=https://meet.yourdomain.com
```

### Backend (`server/.env`)
```env
JITSI_DOMAIN=meet.yourdomain.com
JITSI_SECRET=strong-secret-matching-jitsi
JITSI_APP_ID=collabsphere
```

### Frontend (`client/.env`)
```env
VITE_JITSI_DOMAIN=meet.yourdomain.com
```

---

## ✅ Production Ready Checklist

- [ ] All environment variables configured
- [ ] Domain DNS configured
- [ ] SSL certificate obtained (Let's Encrypt)
- [ ] Firewall ports opened
- [ ] JWT secrets match between services
- [ ] BOSH fix applied and working
- [ ] Tested with your application
- [ ] Monitoring/logging set up
- [ ] Backup strategy in place

---

**Status**: ✅ Ready for production deployment!

