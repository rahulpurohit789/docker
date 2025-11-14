# Jitsi Meet Environment Configuration

## Environment Variables

Create a `.env` file in the `docker/jitsi` directory with the following variables:

```env
# Domain Configuration
JITSI_DOMAIN=localhost
# For production, use your domain: meet.yourdomain.com
# For development, use: localhost

# Ports
HTTP_PORT=80
HTTPS_PORT=443
JVB_PORT=10000
JVB_TCP_PORT=4443

# JWT Authentication (MUST match your backend config)
JWT_APP_ID=collabsphere
JWT_APP_SECRET=your-very-secure-secret-key-change-this-in-production
# IMPORTANT: This must match JITSI_SECRET in your backend .env file

# Let's Encrypt (set to 1 if you have a domain, 0 for self-signed/localhost)
ENABLE_LETSENCRYPT=0
LETSENCRYPT_EMAIL=your-email@example.com

# Docker Host Address (your server's public IP or domain)
# For localhost development: localhost
# For production: your-server-ip or domain
DOCKER_HOST_ADDRESS=localhost

# Auto-generated passwords (will be generated on first run)
# Leave empty - they will be auto-generated
JVB_AUTH_PASSWORD=
JICOFO_AUTH_PASSWORD=
JIBRI_RECORDER_PASSWORD=
JIBRI_XMPP_PASSWORD=

# Config directory (where Jitsi stores its config)
CONFIG=./jitsi-config
```

## Backend Environment Variables

Add to `collabsphere-backend/.env`:

```env
JITSI_DOMAIN=localhost
JITSI_APP_ID=collabsphere
JITSI_SECRET=your-very-secure-secret-key-change-this-in-production
```

**IMPORTANT:** `JITSI_SECRET` must match `JWT_APP_SECRET` in Jitsi `.env` file.

## Frontend Environment Variables

Add to `collabsphere-client/.env`:

```env
VITE_JITSI_DOMAIN=localhost
```

For production, change `localhost` to your actual domain.

