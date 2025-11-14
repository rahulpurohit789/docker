#!/bin/bash
# Fix BOSH proxy configuration - replace localhost with prosody service name
# This runs after the container generates meet.conf from template

# Replace the incorrect proxy_pass line
sed -i 's|proxy_pass http://localhost/http-bind/http-bind;|proxy_pass http://prosody:5280/http-bind;|g' /config/nginx/meet.conf

# Update Host header
sed -i 's|proxy_set_header Host localhost;|proxy_set_header Host $http_host;\n    proxy_set_header X-Forwarded-Proto $scheme;|g' /config/nginx/meet.conf

# Add BOSH-specific settings after proxy_pass line
sed -i '/proxy_pass http:\/\/prosody:5280\/http-bind;/a\
    proxy_buffering off;\
    tcp_nodelay on;\
    keepalive_timeout 65;\
    proxy_read_timeout 60s;' /config/nginx/meet.conf

# Remove duplicate location blocks from custom-meet.conf (keep only first one)
sed -i '/^# Custom BOSH configuration/,/^}$/d' /config/nginx/meet.conf

