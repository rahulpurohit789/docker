#!/bin/bash
# Setup environment variables based on ENVIRONMENT setting
# This script automatically configures JITSI_DOMAIN and DOCKER_HOST_ADDRESS

cd "$(dirname "$0")"

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found!"
    if [ -f env.example ]; then
        echo "Please copy env.example to .env and configure it:"
        echo "  cp env.example .env"
        echo "  nano .env  # or your favorite editor"
    else
        echo "Please create a .env file with ENVIRONMENT=development or ENVIRONMENT=production"
    fi
    exit 1
fi

# Source .env file
set -a
source .env
set +a

# Validate ENVIRONMENT
if [ -z "$ENVIRONMENT" ]; then
    echo "❌ Error: ENVIRONMENT not set in .env file"
    echo "Please set ENVIRONMENT=development or ENVIRONMENT=production"
    exit 1
fi

ENVIRONMENT=$(echo "$ENVIRONMENT" | tr '[:upper:]' '[:lower:]')

# Set domain and host address based on environment
if [ "$ENVIRONMENT" = "development" ]; then
    JITSI_DOMAIN="${DEV_JITSI_DOMAIN:-localhost}"
    DOCKER_HOST_ADDRESS="${DEV_DOCKER_HOST_ADDRESS:-localhost}"
    echo "✅ Environment: DEVELOPMENT"
    echo "   JITSI_DOMAIN=$JITSI_DOMAIN"
    echo "   DOCKER_HOST_ADDRESS=$DOCKER_HOST_ADDRESS"
elif [ "$ENVIRONMENT" = "production" ]; then
    JITSI_DOMAIN="${PROD_JITSI_DOMAIN:-35.154.130.125}"
    DOCKER_HOST_ADDRESS="${PROD_DOCKER_HOST_ADDRESS:-35.154.130.125}"
    echo "✅ Environment: PRODUCTION"
    echo "   JITSI_DOMAIN=$JITSI_DOMAIN"
    echo "   DOCKER_HOST_ADDRESS=$DOCKER_HOST_ADDRESS"
else
    echo "❌ Error: Invalid ENVIRONMENT='$ENVIRONMENT'"
    echo "Must be 'development' or 'production'"
    exit 1
fi

# Export variables for docker-compose
export ENVIRONMENT
export JITSI_DOMAIN
export DOCKER_HOST_ADDRESS

# Update .env file with auto-set values (if they're different)
CURRENT_DOMAIN=$(grep "^JITSI_DOMAIN=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
CURRENT_HOST=$(grep "^DOCKER_HOST_ADDRESS=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")

if [ "$CURRENT_DOMAIN" != "$JITSI_DOMAIN" ] || [ "$CURRENT_HOST" != "$DOCKER_HOST_ADDRESS" ]; then
    echo "📝 Updating .env file with correct values..."
    
    # Update JITSI_DOMAIN
    if grep -q "^JITSI_DOMAIN=" .env; then
        sed -i.bak "s|^JITSI_DOMAIN=.*|JITSI_DOMAIN=$JITSI_DOMAIN|" .env
    else
        echo "JITSI_DOMAIN=$JITSI_DOMAIN" >> .env
    fi
    
    # Update DOCKER_HOST_ADDRESS
    if grep -q "^DOCKER_HOST_ADDRESS=" .env; then
        sed -i.bak "s|^DOCKER_HOST_ADDRESS=.*|DOCKER_HOST_ADDRESS=$DOCKER_HOST_ADDRESS|" .env
    else
        echo "DOCKER_HOST_ADDRESS=$DOCKER_HOST_ADDRESS" >> .env
    fi
    
    rm -f .env.bak
fi

echo ""
echo "✅ Environment configured successfully!"
echo ""

