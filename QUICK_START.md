# SteemAuto Quick Start Guide

Get your SteemAuto instance up and running in minutes!

## Prerequisites

Before you begin, ensure you have:
- Ubuntu 20.04+ or similar Linux distribution
- Sudo access
- 2GB+ RAM
- 20GB+ disk space
- A Steem account with posting authority

## Installation Methods

### Method 1: Automated Installation (Recommended)

```bash
cd /home/user/steemauto
chmod +x scripts/install.sh
./scripts/install.sh
```

The script will guide you through:
1. Installing all dependencies
2. Setting up the database
3. Configuring environment variables
4. Setting up Apache
5. Configuring the firewall

### Method 2: Manual Installation

Follow the detailed steps in [SETUP_GUIDE.md](SETUP_GUIDE.md)

## Post-Installation Steps

### 1. Configure Environment Variables

```bash
cd /home/user/steemauto
cp .env.example .env
nano .env
```

Update these critical values:
- `DB_PASSWORD`: Your MySQL password
- `STEEM_WIF_KEY`: Your Steem posting private key

### 2. Start Services

```bash
# Start all Node.js services
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot
pm2 startup systemd
```

### 3. Verify Installation

```bash
# Check service status
pm2 status

# Run health check
bash scripts/health-check.sh

# View logs
pm2 logs
```

### 4. Access Your Application

Open your browser and navigate to:
- Local: `http://localhost`
- Production: `https://yourdomain.com`

## Common Commands

### Service Management

```bash
# View all services
pm2 list

# View logs
pm2 logs

# Restart all services
pm2 restart all

# Stop all services
pm2 stop all

# Monitor resources
pm2 monit
```

### Database

```bash
# Access MySQL
mysql -u steemauto_user -p steemauto

# Backup database
bash scripts/backup.sh
```

### Apache

```bash
# Restart Apache
sudo systemctl restart apache2

# View error logs
sudo tail -f /var/log/apache2/steemauto-error.log
```

## Troubleshooting

### Services won't start

```bash
# Check logs
pm2 logs --lines 100

# Verify environment variables
cat .env

# Check Node.js version
node -v  # Should be 14+
```

### Database connection failed

```bash
# Test MySQL connection
mysql -u steemauto_user -p -e "SHOW DATABASES;"

# Verify credentials in .env
grep DB_ .env
```

### Apache issues

```bash
# Test configuration
sudo apache2ctl configtest

# Check if port 80 is in use
sudo netstat -tulpn | grep :80
```

## Next Steps

1. **Security**: Follow Phase 1 of [MODERNIZATION_ROADMAP.md](MODERNIZATION_ROADMAP.md)
2. **SSL Setup**: Run `sudo certbot --apache` to enable HTTPS
3. **Monitoring**: Setup health checks and monitoring
4. **Backups**: Configure automated backups

## Getting Help

- **Full Setup Guide**: See [SETUP_GUIDE.md](SETUP_GUIDE.md)
- **Modernization Plan**: See [MODERNIZATION_ROADMAP.md](MODERNIZATION_ROADMAP.md)
- **Review Report**: See review in project files

## Important Security Notes

⚠️ **Before going to production:**
1. Change all default passwords
2. Enable HTTPS with SSL certificate
3. Setup firewall (UFW)
4. Enable fail2ban
5. Review and fix security vulnerabilities (see review report)

## Support

For issues and questions:
1. Check logs: `pm2 logs`
2. Run health check: `bash scripts/health-check.sh`
3. Review setup guide for detailed troubleshooting

---

**Last Updated**: 2025-01-16
**Version**: 1.0.0
