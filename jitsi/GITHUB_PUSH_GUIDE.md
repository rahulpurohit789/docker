# GitHub Push Guide for Jitsi Docker Setup

## ✅ **YES - Safe to Push to GitHub:**

### Configuration Files:
- ✅ `docker-compose.yml` - Docker configuration (no secrets)
- ✅ `jitsi-config/web/config.js` - Jitsi web configuration template
- ✅ `jitsi-config/web/interface_config.js` - UI configuration
- ✅ `jitsi-config/web/nginx/*.conf` - Nginx configuration files
- ✅ `jitsi-config/jvb/jvb.conf` - JVB configuration template
- ✅ `jitsi-config/jicofo/jicofo.conf` - Jicofo configuration template
- ✅ `jitsi-config/jvb/logging.properties` - Logging configuration
- ✅ `jitsi-config/jicofo/logging.properties` - Logging configuration
- ✅ `jitsi-config/prosody/prosody.cfg.lua` - Prosody main config
- ✅ `jitsi-config/prosody/conf.d/*.lua` - Prosody module configs

### Scripts:
- ✅ `generate-passwords.sh` - Password generation script
- ✅ `generate-passwords.ps1` - PowerShell password generation script
- ✅ `start-jitsi.sh` - Startup script

### Documentation:
- ✅ `README.md` - Setup documentation
- ✅ `SETUP.md` - Configuration guide
- ✅ `NEXT_STEPS.md` - Post-setup instructions
- ✅ `WINDOWS_SETUP.md` - Windows-specific guide
- ✅ `BOSH_FIX.md` - BOSH configuration notes
- ✅ `GIT_BASH_COMMANDS.md` - Git Bash instructions
- ✅ `.gitignore` - Git ignore rules

---

## ❌ **NO - NEVER Push These Files:**

### Secrets and Passwords:
- ❌ `.env` - Contains JWT secrets, passwords, IP addresses
- ❌ `.env.local`, `.env.*` - Any environment files with secrets
- ❌ `*.env.backup`, `.env.bak` - Backup files with secrets

### Generated Configuration Data:
- ❌ `jitsi-config/prosody/data/` - Contains user passwords, account data
  - `auth%2elocalhost/accounts/*.dat` - Password hashes (focus.dat, jvb.dat, jibri.dat)
  - `prosody.pid` - Process ID file

### Certificates and Keys:
- ❌ `jitsi-config/prosody/certs/` - SSL certificates (if any)
- ❌ `jitsi-config/web/keys/` - Private keys
- ❌ `jitsi-config/web/letsencrypt/` - Let's Encrypt certificates

### Runtime Files:
- ❌ Any `.log` files in jitsi-config
- ❌ Docker volumes if mounted locally

---

## 📋 **Checklist Before Pushing:**

Before committing and pushing, verify:

```bash
# Check what will be committed
git status

# Review changes (make sure no .env or sensitive files)
git diff --cached

# If you see any sensitive files in the output, DO NOT commit them
```

### Quick Check Commands:

```bash
# Make sure .env is not tracked
git check-ignore docker/jitsi/.env
# Should output: docker/jitsi/.env (if properly ignored)

# Check if sensitive data folder is ignored
git check-ignore docker/jitsi/jitsi-config/prosody/data/
# Should output the path if properly ignored

# List files that will be pushed (verify no secrets)
git ls-files docker/jitsi/ | grep -E '\.(env|dat|key|crt|pem)$'
# Should output nothing (or only safe config templates)
```

---

## 🔒 **Security Best Practices:**

1. **Never commit `.env` files** - These contain production secrets
2. **Create `.env.example`** - Template file with placeholders (safe to push)
3. **Use `.gitignore`** - Ensure sensitive paths are ignored
4. **Review before pushing** - Always check `git status` and `git diff`
5. **Rotate secrets if exposed** - If you accidentally push secrets, rotate them immediately

---

## 📝 **Recommended Setup:**

### 1. Create `.env.example` file (safe template):

```bash
cd docker/jitsi
cp .env .env.example  # If .env exists
# Then edit .env.example to replace secrets with placeholders
```

`.env.example` should look like:
```env
JITSI_DOMAIN=your-domain-or-ip
DOCKER_HOST_ADDRESS=your-server-ip
JWT_APP_SECRET=YOUR-SECRET-HERE
# ... other config without actual secrets
```

### 2. Ensure `.gitignore` is in place:

The `.gitignore` file in `docker/jitsi/` should exclude:
- `.env` files
- `jitsi-config/prosody/data/`
- `jitsi-config/prosody/certs/`
- `jitsi-config/web/letsencrypt/`
- `jitsi-config/web/keys/`

---

## ✅ **Summary:**

**You can safely push:**
- All configuration template files
- Documentation files
- Scripts
- `docker-compose.yml`

**DO NOT push:**
- `.env` file (contains secrets)
- `jitsi-config/prosody/data/` (contains password hashes)
- Any certificates or keys
- Generated passwords

The `.gitignore` file has been created to automatically exclude these sensitive files.

---

## 🚀 **Safe Push Command:**

```bash
# 1. Check what will be committed
git status

# 2. If everything looks good (no .env, no data/ folders)
git add docker/

# 3. Commit
git commit -m "Add Jitsi Docker setup configuration"

# 4. Push
git push origin main
```

---

## ⚠️ **If You Already Pushed Sensitive Files:**

If you've already pushed `.env` or sensitive files:

1. **Immediately rotate all secrets** in `.env`
2. **Remove from Git history:**
   ```bash
   git rm --cached docker/jitsi/.env
   git commit -m "Remove sensitive .env file"
   ```
3. **Update secrets** on all servers using the old secrets
4. **Force push** (if necessary, coordinate with team):
   ```bash
   git push origin main --force
   ```
   ⚠️ Only do this if you're sure and team is aware!

---

**Your `.gitignore` is now configured. Safe to push! ✅**

