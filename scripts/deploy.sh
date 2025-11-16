#!/bin/bash
#
# SteemAuto Deployment Script
# This script handles safe deployment of updates
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running from correct directory
if [ ! -f "package.json" ]; then
    error "Please run this script from the steemauto root directory"
fi

echo -e "${GREEN}"
echo "==================================="
echo "   SteemAuto Deployment Script"
echo "==================================="
echo -e "${NC}\n"

# 1. Create backup
log "Creating backup before deployment..."
if [ -f scripts/backup.sh ]; then
    bash scripts/backup.sh
else
    warn "Backup script not found. Skipping backup..."
fi

# 2. Pull latest changes
log "Pulling latest changes from git..."
git pull origin $(git branch --show-current)

# 3. Install/update dependencies
log "Installing/updating Node.js dependencies..."
npm install

# 4. Run database migrations (if any)
if [ -d "migrations" ]; then
    log "Running database migrations..."
    # Add migration logic here when implemented
else
    log "No migrations directory found. Skipping..."
fi

# 5. Restart Node.js services
log "Restarting PM2 services..."
pm2 restart ecosystem.config.js

# 6. Reload Apache
log "Reloading Apache..."
sudo systemctl reload apache2

# 7. Wait for services to stabilize
log "Waiting for services to stabilize..."
sleep 5

# 8. Check service health
log "Checking service health..."
pm2 list | grep -E 'steemauto-'

# 9. Clear cache (if applicable)
if [ -d "cache" ]; then
    log "Clearing cache..."
    rm -rf cache/*
fi

# 10. Display logs
log "Recent PM2 logs:"
pm2 logs --lines 20 --nostream

echo -e "\n${GREEN}"
echo "==================================="
echo "   Deployment Complete!"
echo "==================================="
echo -e "${NC}\n"

echo "Next steps:"
echo "1. Check logs: pm2 logs"
echo "2. Monitor services: pm2 monit"
echo "3. Run health check: bash scripts/health-check.sh"
echo
