#!/bin/bash
# Quick script to fix BOSH configuration after container restart

cd "$(dirname "$0")"

echo "Applying BOSH configuration fix..."

# Wait for container to be ready
sleep 3

# Apply fix
docker-compose exec -T web bash -c "bash /config/99-fix-bosh.sh && nginx -s reload" 2>&1

if [ $? -eq 0 ]; then
    echo "✅ BOSH configuration fixed successfully!"
    echo "✅ Please refresh your browser and try again"
else
    echo "❌ Error fixing BOSH configuration"
    echo "Try manually: docker-compose exec web bash /config/99-fix-bosh.sh"
fi

