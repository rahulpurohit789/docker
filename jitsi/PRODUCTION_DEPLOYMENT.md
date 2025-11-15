# Jitsi Production Deployment Guide - AWS EC2

## 🎯 Quick Summary

✅ **Jitsi is working locally!**  
✅ **Ready for production deployment**  
✅ **Safe to push to GitHub** (sensitive files are protected)

---

## 📋 Production Readiness Status

### ✅ Completed
- [x] BOSH configuration fixed
- [x] JWT authentication configured
- [x] Guest access enabled for testing
- [x] Docker configuration optimized
- [x] Startup scripts created
- [x] Security files protected (.gitignore)
- [x] Documentation created

### ⚠️ Required for Production
- [ ] Update `.env` with production domain
- [ ] Configure DNS A record
- [ ] Enable Let's Encrypt SSL
- [ ] Use strong JWT secrets
- [ ] Update backend `.env`
- [ ] Update frontend `.env`

---

## 🚀 Production Deployment Steps

### Step 1: Prepare Production Environment Variables

**On EC2, create/update `docker/jitsi/.env`:**

```env
# Production Configuration
JITSI_DOMAIN=meet.yourdomain.com
DOCKER_HOST_ADDRESS=your-ec2-elastic-ip
ENABLE_LETSENCRYPT=1
LETSENCRYPT_EMAIL=your-email@example.com
PUBLIC_URL=https://meet.yourdomain.com

# Strong JWT Secret (generate a secure random string)
JWT_APP_SECRET=your-production-secret-minimum-32-characters-random
JWT_APP_ID=collabsphere

# Ports
HTTP_PORT=80
HTTPS_PORT=443
JVB_PORT=10000
JVB_TCP_PORT=4443

# Config
CONFIG=./jitsi-config

# Passwords (generate with generate-passwords.sh)
JVB_AUTH_PASSWORD=generated-password
JICOFO_AUTH_PASSWORD=generated-password
JIBRI_RECORDER_PASSWORD=generated-password
JIBRI_XMPP_PASSWORD=generated-password
```

### Step 2: Update Backend Environment

**On your backend server (`server/.env`):**

```env
# Jitsi Configuration - MUST match Jitsi .env
JITSI_DOMAIN=meet.yourdomain.com
JITSI_APP_ID=collabsphere
JITSI_SECRET=your-production-secret-minimum-32-characters-random
# IMPORTANT: Must exactly match JWT_APP_SECRET in Jitsi .env
```

### Step 3: Update Frontend Environment

**On your frontend (`client/.env`):**

```env
VITE_JITSI_DOMAIN=meet.yourdomain.com
```

### Step 4: Deploy to EC2

```bash
# On EC2 instance
cd ~/jitsi

# Update .env with production values
nano .env

# Start with automatic BOSH fix
./start-jitsi-fixed.sh

# Or manually:
docker-compose up -d
sleep 15
docker-compose exec -T web bash -c "bash /config/99-fix-bosh.sh && nginx -s reload"
```

### Step 5: Verify Production Deployment

1. **Check Services**: `docker-compose ps` (all "Up")
2. **Test HTTPS**: Visit `https://meet.yourdomain.com`
3. **Test from App**: Create meeting and join through your application
4. **Check SSL**: Verify Let's Encrypt certificate is valid

---

## 🔒 Security Checklist for Production

- [ ] **Strong JWT Secret**: 32+ character random string
- [ ] **Secrets Match**: `JWT_APP_SECRET` = `JITSI_SECRET`
- [ ] **HTTPS Enabled**: `ENABLE_LETSENCRYPT=1`
- [ ] **Domain Configured**: DNS A record pointing to EC2
- [ ] **Firewall Open**: Ports 80, 443, 10000/udp, 4443/tcp
- [ ] **Authentication Required**: Users must go through your app (JWT)
- [ ] **No Direct Access**: Don't share direct Jitsi URLs without tokens

---

## 📦 What's Safe to Push to GitHub

### ✅ Safe to Push
- All configuration templates
- Scripts (generate-passwords.sh, start-jitsi-fixed.sh, etc.)
- Documentation files
- `docker-compose.yml`
- `.env.example` (template file)
- BOSH fix scripts

### ❌ Protected (Won't be pushed)
- `.env` files (protected by .gitignore)
- `jitsi-config/prosody/data/` (password hashes)
- `jitsi-config/prosody/certs/` (certificates)
- `jitsi-config/web/letsencrypt/` (SSL certs)

---

## 🎉 Ready to Push!

Your Jitsi setup is:
- ✅ **Working locally**
- ✅ **Production-ready** (with proper configuration)
- ✅ **Safe to push** (secrets protected)

**Next Steps:**
1. Review what will be committed: `git status docker/`
2. Push to GitHub: `git add docker/ && git commit -m "Add Jitsi Docker setup" && git push`
3. Deploy to EC2 following the production guide above

---

## 📚 Additional Resources

- `PRODUCTION_READINESS.md` - Detailed production checklist
- `PRE_PUSH_CHECKLIST.md` - Pre-push verification
- `README.md` - General setup guide
- `BOSH_FIX_SOLUTION.md` - BOSH configuration details

