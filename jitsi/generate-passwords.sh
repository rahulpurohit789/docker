#!/bin/bash

# Generate random passwords if not set
if [ -z "$JVB_AUTH_PASSWORD" ]; then
    export JVB_AUTH_PASSWORD=$(openssl rand -hex 16)
fi

if [ -z "$JICOFO_AUTH_PASSWORD" ]; then
    export JICOFO_AUTH_PASSWORD=$(openssl rand -hex 16)
fi

if [ -z "$JIBRI_RECORDER_PASSWORD" ]; then
    export JIBRI_RECORDER_PASSWORD=$(openssl rand -hex 16)
fi

if [ -z "$JIBRI_XMPP_PASSWORD" ]; then
    export JIBRI_XMPP_PASSWORD=$(openssl rand -hex 16)
fi

# Update .env file if it exists
if [ -f .env ]; then
    sed -i.bak "s/^JVB_AUTH_PASSWORD=.*/JVB_AUTH_PASSWORD=$JVB_AUTH_PASSWORD/" .env
    sed -i.bak "s/^JICOFO_AUTH_PASSWORD=.*/JICOFO_AUTH_PASSWORD=$JICOFO_AUTH_PASSWORD/" .env
    sed -i.bak "s/^JIBRI_RECORDER_PASSWORD=.*/JIBRI_RECORDER_PASSWORD=$JIBRI_RECORDER_PASSWORD/" .env
    sed -i.bak "s/^JIBRI_XMPP_PASSWORD=.*/JIBRI_XMPP_PASSWORD=$JIBRI_XMPP_PASSWORD/" .env
    rm -f .env.bak
    echo "Passwords generated and saved to .env"
else
    echo "Warning: .env file not found. Passwords generated but not saved."
    echo "JVB_AUTH_PASSWORD=$JVB_AUTH_PASSWORD"
    echo "JICOFO_AUTH_PASSWORD=$JICOFO_AUTH_PASSWORD"
    echo "JIBRI_RECORDER_PASSWORD=$JIBRI_RECORDER_PASSWORD"
    echo "JIBRI_XMPP_PASSWORD=$JIBRI_XMPP_PASSWORD"
fi

