#!/bin/bash
#
# SteemAuto Health Check Script
# This script checks the health of all services
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== SteemAuto Health Check ===${NC}\n"

# Check Apache
echo -n "Apache: "
if systemctl is-active --quiet apache2; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not running${NC}"
fi

# Check MySQL
echo -n "MySQL: "
if systemctl is-active --quiet mysql; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not running${NC}"
fi

# Check PM2 services
echo -e "\nPM2 Services:"
pm2 list | grep -E 'steemauto-' || echo -e "${RED}No PM2 services found${NC}"

# Check disk space
echo -e "\nDisk Space:"
df -h / | tail -1 | awk '{print "  Used: " $3 " / " $2 " (" $5 ")"}'

# Check memory
echo -e "\nMemory Usage:"
free -h | grep Mem | awk '{print "  Used: " $3 " / " $2}'

# Check database connection
echo -e "\nDatabase Connection:"
if [ -f /home/user/steemauto/.env ]; then
    source <(grep -E '^(DB_USER|DB_PASSWORD|DB_NAME)=' /home/user/steemauto/.env | sed 's/^/export /')

    if mysql -u $DB_USER -p$DB_PASSWORD -e "USE $DB_NAME;" 2>/dev/null; then
        echo -e "  ${GREEN}✓ Connected${NC}"

        # Count users
        user_count=$(mysql -u $DB_USER -p$DB_PASSWORD -N -e "SELECT COUNT(*) FROM $DB_NAME.users;" 2>/dev/null)
        echo "  Total users: $user_count"
    else
        echo -e "  ${RED}✗ Connection failed${NC}"
    fi
else
    echo -e "  ${YELLOW}! .env file not found${NC}"
fi

# Check log file sizes
echo -e "\nLog File Sizes:"
if [ -d /home/user/steemauto/logs ]; then
    du -sh /home/user/steemauto/logs/* 2>/dev/null | head -5
else
    echo "  No log files found"
fi

# Check recent errors
echo -e "\nRecent Errors (last 10):"
if [ -f /var/log/apache2/steemauto-error.log ]; then
    tail -10 /var/log/apache2/steemauto-error.log | grep -i error || echo "  No recent errors"
else
    echo "  Apache error log not found"
fi

# Check SSL certificate (if exists)
echo -e "\nSSL Certificate:"
if command -v certbot &> /dev/null; then
    cert_info=$(sudo certbot certificates 2>/dev/null | grep -A 2 "Certificate Name" | head -3)
    if [ -n "$cert_info" ]; then
        echo "$cert_info"
    else
        echo "  No certificates found"
    fi
else
    echo "  Certbot not installed"
fi

echo -e "\n${GREEN}=== Health Check Complete ===${NC}\n"
