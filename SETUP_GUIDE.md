# SteemAuto Complete Setup Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Server Requirements](#server-requirements)
3. [Initial Setup](#initial-setup)
4. [Database Configuration](#database-configuration)
5. [Backend Setup (Node.js)](#backend-setup-nodejs)
6. [Frontend Setup (PHP)](#frontend-setup-php)
7. [Security Hardening](#security-hardening)
8. [Service Management](#service-management)
9. [Verification & Testing](#verification--testing)
10. [Troubleshooting](#troubleshooting)
11. [Next Steps - Modernization](#next-steps---modernization)

---

## Prerequisites

### Required Software
- **Operating System**: Ubuntu 20.04 LTS or newer (or compatible Linux distribution)
- **Node.js**: v14.x or newer
- **npm**: v6.x or newer
- **PHP**: 7.4 or newer (8.0+ recommended)
- **MySQL**: 5.7 or 8.0
- **Apache2** or **Nginx**: Web server
- **PM2**: Process manager for Node.js
- **Git**: Version control
- **Certbot**: For SSL certificates (Let's Encrypt)

### Accounts & Credentials Needed
- **Steem Account**: Your Steem blockchain account
- **SteemConnect App**: OAuth application credentials
- **Domain Name**: (Optional but recommended) For production deployment
- **Server**: VPS or dedicated server with at least 2GB RAM

---

## Server Requirements

### Minimum Specifications
- **CPU**: 2 cores
- **RAM**: 2GB (4GB recommended)
- **Storage**: 20GB SSD
- **Network**: Stable internet connection
- **Ports**: 80 (HTTP), 443 (HTTPS), 7412 (Node.js upvote service - internal)

### Recommended Specifications
- **CPU**: 4 cores
- **RAM**: 8GB
- **Storage**: 50GB SSD
- **Backup**: Automated daily backups

---

## Initial Setup

### 1. Update System
```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Install Required Packages
```bash
# Install Apache2
sudo apt install apache2 -y

# Install PHP and extensions
sudo apt install php8.1 php8.1-cli php8.1-mysql php8.1-curl php8.1-mbstring php8.1-xml -y

# Install MySQL
sudo apt install mysql-server -y

# Install Node.js (using NodeSource repository)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install nodejs -y

# Install PM2 globally
sudo npm install -g pm2

# Install Git
sudo apt install git -y

# Install Certbot for SSL
sudo apt install certbot python3-certbot-apache -y
```

### 3. Verify Installations
```bash
php -v        # Should show PHP 8.1+
node -v       # Should show v18.x+
npm -v        # Should show v9.x+
mysql --version
apache2 -v
pm2 -v
```

---

## Database Configuration

### 1. Secure MySQL Installation
```bash
sudo mysql_secure_installation
```

Follow the prompts:
- Set root password: **YES** (choose a strong password)
- Remove anonymous users: **YES**
- Disallow root login remotely: **YES**
- Remove test database: **YES**
- Reload privilege tables: **YES**

### 2. Create Database and User
```bash
sudo mysql -u root -p
```

Execute the following SQL commands:
```sql
-- Create database
CREATE DATABASE steemauto CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create dedicated user (CHANGE PASSWORD!)
CREATE USER 'steemauto_user'@'localhost' IDENTIFIED BY 'STRONG_PASSWORD_HERE';

-- Grant privileges
GRANT ALL PRIVILEGES ON steemauto.* TO 'steemauto_user'@'localhost';

-- Flush privileges
FLUSH PRIVILEGES;

-- Exit MySQL
EXIT;
```

### 3. Import Database Schema
```bash
cd /home/user/steemauto
mysql -u steemauto_user -p steemauto < mysql.sql
```

### 4. Verify Database
```bash
mysql -u steemauto_user -p steemauto -e "SHOW TABLES;"
```

You should see 11 tables:
- blacklist
- commentupvote
- donations
- fanbase
- fans
- followers
- posts
- trailers
- upvotedcomments
- upvotelater
- users

---

## Backend Setup (Node.js)

### 1. Navigate to Project Directory
```bash
cd /home/user/steemauto
```

### 2. Create package.json
```bash
cat > package.json << 'EOF'
{
  "name": "steemauto",
  "version": "1.0.0",
  "description": "SteemAuto - Steem Blockchain Automation Platform",
  "main": "nodejs/upvote.js",
  "scripts": {
    "start": "pm2 start ecosystem.config.js",
    "stop": "pm2 stop ecosystem.config.js",
    "restart": "pm2 restart ecosystem.config.js",
    "logs": "pm2 logs",
    "monitor": "pm2 monit"
  },
  "keywords": ["steem", "blockchain", "automation"],
  "author": "SteemAuto",
  "license": "GPL-3.0",
  "dependencies": {
    "steem": "^0.7.7",
    "mysql": "^2.18.1",
    "node-fetch": "^2.6.7"
  },
  "engines": {
    "node": ">=14.0.0"
  }
}
EOF
```

### 3. Install Dependencies
```bash
npm install
```

### 4. Create Environment Configuration
```bash
# Create .env file
cat > .env << 'EOF'
# Database Configuration
DB_HOST=127.0.0.1
DB_USER=steemauto_user
DB_PASSWORD=STRONG_PASSWORD_HERE
DB_NAME=steemauto

# Steem Configuration
STEEM_WIF_KEY=YOUR_POSTING_PRIVATE_KEY_HERE
STEEM_RPC=wss://api.steemit.com
STEEM_RPC_HTTP=https://api.steemit.com

# Application Configuration
NODE_ENV=production
NODEJS_SERVER=http://127.0.0.1
UPVOTE_PORT=7412
EOF
```

### 5. Update config.js to Use Environment Variables
```bash
cat > nodejs/config.js << 'EOF'
require('dotenv').config();

var config = {}
config.db = {}
config.db.pw = process.env.DB_PASSWORD || ''
config.db.user = process.env.DB_USER || 'root'
config.db.host = process.env.DB_HOST || '127.0.0.1'
config.db.name = process.env.DB_NAME || 'steemauto'
config.wifkey = process.env.STEEM_WIF_KEY || ''
config.rpc = process.env.STEEM_RPC || 'wss://api.steemit.com'
config.rpc2 = process.env.STEEM_RPC || 'wss://api.steemit.com'
config.rpc3 = process.env.STEEM_RPC || 'wss://api.steemit.com'
config.steemd = process.env.STEEM_RPC_HTTP || 'https://api.steemit.com'
config.isSteemd = 1 // Use steemd API
config.rpchttp = process.env.STEEM_RPC_HTTP || 'https://api.steemit.com'
config.nodejssrv = process.env.NODEJS_SERVER || 'http://127.0.0.1'

// Validate required config
if (!config.wifkey && process.env.NODE_ENV === 'production') {
  console.error('ERROR: STEEM_WIF_KEY is required in production');
  process.exit(1);
}

module.exports = config
EOF
```

### 6. Install dotenv
```bash
npm install dotenv --save
```

### 7. Create PM2 Ecosystem Configuration
```bash
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'steemauto-upvote',
      script: './nodejs/upvote.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/upvote-error.log',
      out_file: './logs/upvote-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    {
      name: 'steemauto-trail',
      script: './nodejs/trail.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/trail-error.log',
      out_file: './logs/trail-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    {
      name: 'steemauto-fan',
      script: './nodejs/fan.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/fan-error.log',
      out_file: './logs/fan-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    {
      name: 'steemauto-commentup',
      script: './nodejs/commentup.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/commentup-error.log',
      out_file: './logs/commentup-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    {
      name: 'steemauto-schedule',
      script: './nodejs/schedule_posts.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/schedule-error.log',
      out_file: './logs/schedule-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    {
      name: 'steemauto-delay',
      script: './nodejs/delay.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '300M',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/delay-error.log',
      out_file: './logs/delay-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    {
      name: 'steemauto-claimreward',
      script: './nodejs/claimreward.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '300M',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/claimreward-error.log',
      out_file: './logs/claimreward-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    {
      name: 'steemauto-votepower',
      script: './nodejs/vote_power.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '300M',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/votepower-error.log',
      out_file: './logs/votepower-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    {
      name: 'steemauto-donations',
      script: './nodejs/donations.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '300M',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/donations-error.log',
      out_file: './logs/donations-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    {
      name: 'steemauto-updatepower',
      script: './nodejs/update_power.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '300M',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/updatepower-error.log',
      out_file: './logs/updatepower-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    {
      name: 'steemauto-fanlimitreset',
      script: './nodejs/fan_dailylimit_reset.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '300M',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/fanlimitreset-error.log',
      out_file: './logs/fanlimitreset-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    {
      name: 'steemauto-unauthorized',
      script: './nodejs/unauthorized_users.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '300M',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/unauthorized-error.log',
      out_file: './logs/unauthorized-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    }
  ]
};
EOF
```

### 8. Create Logs Directory
```bash
mkdir -p logs
chmod 755 logs
```

### 9. Secure the .env File
```bash
chmod 600 .env
```

### 10. Update .gitignore
```bash
cat >> .gitignore << 'EOF'

# Environment files
.env
.env.local
.env.production

# Logs
logs/
*.log

# Node modules
node_modules/

# PM2
.pm2/

# Configuration with credentials
inc/conf/db.php
nodejs/config.js.bak
EOF
```

---

## Frontend Setup (PHP)

### 1. Update Database Configuration
```bash
cat > inc/conf/db.php << 'EOF'
<?php
// Load environment variables from .env file
$envFile = __DIR__ . '/../../.env';
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos(trim($line), '#') === 0) continue;
        list($name, $value) = explode('=', $line, 2);
        $_ENV[trim($name)] = trim($value);
    }
}

$server = $_ENV['DB_HOST'] ?? 'localhost';
$user = $_ENV['DB_USER'] ?? 'root';
$pw = $_ENV['DB_PASSWORD'] ?? '';
$db = $_ENV['DB_NAME'] ?? 'steemauto';

$conn = new mysqli($server, $user, $pw, $db);
$conn->set_charset('utf8mb4');

if ($conn->connect_error) {
    error_log("Database connection failed: " . $conn->connect_error);
    die("Database connection failed. Please contact administrator.");
}
?>
EOF
```

### 2. Configure Apache Virtual Host
```bash
sudo cat > /etc/apache2/sites-available/steemauto.conf << 'EOF'
<VirtualHost *:80>
    ServerAdmin admin@yourdomain.com
    ServerName yourdomain.com
    ServerAlias www.yourdomain.com
    DocumentRoot /home/user/steemauto

    <Directory /home/user/steemauto>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Deny access to sensitive directories
    <Directory /home/user/steemauto/inc>
        Require all denied
    </Directory>

    <Directory /home/user/steemauto/nodejs>
        Require all denied
    </Directory>

    <Directory /home/user/steemauto/.git>
        Require all denied
    </Directory>

    # Logging
    ErrorLog ${APACHE_LOG_DIR}/steemauto-error.log
    CustomLog ${APACHE_LOG_DIR}/steemauto-access.log combined

    # Security Headers
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
</VirtualHost>
EOF
```

### 3. Enable Apache Modules
```bash
sudo a2enmod rewrite
sudo a2enmod headers
sudo a2enmod ssl
```

### 4. Enable Site and Restart Apache
```bash
sudo a2ensite steemauto.conf
sudo a2dissite 000-default.conf
sudo apache2ctl configtest
sudo systemctl restart apache2
```

### 5. Set Proper Permissions
```bash
cd /home/user/steemauto

# Set ownership
sudo chown -R www-data:www-data .

# Set directory permissions
find . -type d -exec chmod 755 {} \;

# Set file permissions
find . -type f -exec chmod 644 {} \;

# Protect sensitive files
chmod 600 .env
chmod 600 inc/conf/db.php

# Make logs writable
chmod 755 logs
chmod 666 logs/*.log 2>/dev/null || true
```

---

## Security Hardening

### 1. Configure Firewall
```bash
# Install UFW (if not installed)
sudo apt install ufw -y

# Allow SSH (IMPORTANT: Do this first!)
sudo ufw allow 22/tcp

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw --force enable

# Check status
sudo ufw status
```

### 2. Install and Configure Fail2Ban
```bash
# Install
sudo apt install fail2ban -y

# Create local configuration
sudo cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 22

[apache-auth]
enabled = true
port = http,https

[apache-badbots]
enabled = true
port = http,https

[apache-noscript]
enabled = true
port = http,https

[apache-overflows]
enabled = true
port = http,https
EOF

# Restart Fail2Ban
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban
```

### 3. Setup SSL Certificate (Let's Encrypt)
```bash
# Make sure your domain points to your server first!

# Obtain certificate
sudo certbot --apache -d yourdomain.com -d www.yourdomain.com

# Follow prompts:
# - Enter email address
# - Agree to terms
# - Choose whether to redirect HTTP to HTTPS (recommend: YES)

# Test auto-renewal
sudo certbot renew --dry-run
```

### 4. Create Security Helper Functions (PHP)
```bash
cat > inc/dep/security.php << 'EOF'
<?php
/**
 * Security helper functions
 */

// Prevent direct access
if (!defined('STEEMAUTO_LOADED')) {
    die('Direct access not permitted');
}

/**
 * Sanitize input
 */
function sanitize_input($data) {
    $data = trim($data);
    $data = stripslashes($data);
    $data = htmlspecialchars($data, ENT_QUOTES, 'UTF-8');
    return $data;
}

/**
 * Validate CSRF token
 */
function validate_csrf_token() {
    if (!isset($_POST['csrf_token']) || !isset($_SESSION['csrf_token'])) {
        return false;
    }
    return hash_equals($_SESSION['csrf_token'], $_POST['csrf_token']);
}

/**
 * Generate CSRF token
 */
function generate_csrf_token() {
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

/**
 * Validate username (Steem format)
 */
function validate_steem_username($username) {
    return preg_match('/^[a-z][a-z0-9\-\.]{2,15}$/', $username);
}

/**
 * Rate limiting check
 */
function check_rate_limit($identifier, $max_attempts = 5, $timeframe = 300) {
    session_start();
    $key = 'rate_limit_' . $identifier;

    if (!isset($_SESSION[$key])) {
        $_SESSION[$key] = ['count' => 1, 'start' => time()];
        return true;
    }

    $data = $_SESSION[$key];

    // Reset if timeframe expired
    if (time() - $data['start'] > $timeframe) {
        $_SESSION[$key] = ['count' => 1, 'start' => time()];
        return true;
    }

    // Check limit
    if ($data['count'] >= $max_attempts) {
        return false;
    }

    $_SESSION[$key]['count']++;
    return true;
}
?>
EOF
```

### 5. Enable PHP Security Settings
```bash
# Edit PHP configuration
sudo nano /etc/php/8.1/apache2/php.ini

# Find and update these settings:
# expose_php = Off
# display_errors = Off
# log_errors = On
# error_log = /var/log/php/error.log
# max_execution_time = 30
# max_input_time = 60
# memory_limit = 256M
# post_max_size = 8M
# upload_max_filesize = 2M
# session.cookie_httponly = 1
# session.cookie_secure = 1
# session.use_strict_mode = 1

# Create log directory
sudo mkdir -p /var/log/php
sudo chown www-data:www-data /var/log/php

# Restart Apache
sudo systemctl restart apache2
```

---

## Service Management

### 1. Start All Node.js Services
```bash
cd /home/user/steemauto

# Start all services
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot
pm2 startup systemd
# Follow the command it provides (run as root)
```

### 2. Manage Services
```bash
# View all services
pm2 list

# View logs
pm2 logs

# View specific service logs
pm2 logs steemauto-upvote

# Restart all services
pm2 restart all

# Restart specific service
pm2 restart steemauto-trail

# Stop all services
pm2 stop all

# Monitor services
pm2 monit

# Service details
pm2 show steemauto-upvote
```

### 3. Check Apache Status
```bash
# Status
sudo systemctl status apache2

# Restart
sudo systemctl restart apache2

# View error logs
sudo tail -f /var/log/apache2/steemauto-error.log

# View access logs
sudo tail -f /var/log/apache2/steemauto-access.log
```

### 4. Check MySQL Status
```bash
# Status
sudo systemctl status mysql

# Access MySQL
mysql -u steemauto_user -p steemauto

# View slow queries
sudo tail -f /var/log/mysql/error.log
```

---

## Verification & Testing

### 1. Test Database Connection
```bash
mysql -u steemauto_user -p steemauto -e "SELECT COUNT(*) FROM users;"
```

### 2. Test PHP Configuration
```bash
# Create test file
echo "<?php phpinfo(); ?>" | sudo tee /home/user/steemauto/test.php

# Visit: http://yourdomain.com/test.php
# Then delete it:
sudo rm /home/user/steemauto/test.php
```

### 3. Test Node.js Services
```bash
# Check if upvote service is listening
curl http://localhost:7412/

# Check PM2 status
pm2 status

# Check logs for errors
pm2 logs --lines 50
```

### 4. Test Frontend Pages
Visit these URLs:
- `http://yourdomain.com/` - Homepage
- `http://yourdomain.com/dash.php` - Dashboard (requires login)
- `http://yourdomain.com/api.php?i=1&user=steemauto` - API test
- `http://yourdomain.com/faq.php` - FAQ page

### 5. Monitor System Resources
```bash
# CPU and Memory
htop

# Disk usage
df -h

# Service resource usage
pm2 monit
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Apache won't start
```bash
# Check configuration
sudo apache2ctl configtest

# Check error logs
sudo tail -50 /var/log/apache2/error.log

# Check if port 80 is in use
sudo netstat -tulpn | grep :80
```

#### 2. Database connection failed
```bash
# Verify MySQL is running
sudo systemctl status mysql

# Test connection
mysql -u steemauto_user -p -e "SHOW DATABASES;"

# Check credentials in .env file
cat .env | grep DB_
```

#### 3. PM2 services won't start
```bash
# Check logs
pm2 logs steemauto-upvote --lines 100

# Check Node.js version
node -v  # Should be 14+

# Verify dependencies
cd /home/user/steemauto
npm list

# Reinstall dependencies
rm -rf node_modules
npm install
```

#### 4. Permission denied errors
```bash
cd /home/user/steemauto

# Reset permissions
sudo chown -R www-data:www-data .
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
chmod 600 .env
chmod 755 logs
```

#### 5. SSL certificate issues
```bash
# Renew certificate
sudo certbot renew

# Check certificate status
sudo certbot certificates

# Test configuration
sudo apache2ctl configtest
```

#### 6. High memory usage
```bash
# Check which service is using memory
pm2 monit

# Restart specific service
pm2 restart steemauto-trail

# Check MySQL
sudo mysqladmin -u root -p processlist
```

---

## Next Steps - Modernization

Now that the application is set up properly, here's the roadmap for modernization:

### Phase 1: Security Improvements (Week 1-2)
- [ ] Fix all SQL injection vulnerabilities
- [ ] Implement CSRF protection
- [ ] Add XSS protection to all outputs
- [ ] Secure WIF key transmission
- [ ] Implement rate limiting
- [ ] Add comprehensive logging

### Phase 2: Code Quality (Week 3-4)
- [ ] Set up ESLint and PHP_CodeSniffer
- [ ] Write unit tests (Jest for Node.js, PHPUnit for PHP)
- [ ] Refactor duplicated code
- [ ] Add TypeScript to Node.js services
- [ ] Implement error handling middleware
- [ ] Add code documentation

### Phase 3: Infrastructure (Week 5-6)
- [ ] Set up CI/CD pipeline (GitHub Actions)
- [ ] Implement Redis for caching
- [ ] Add database migrations system
- [ ] Set up monitoring (Prometheus + Grafana)
- [ ] Implement backup automation
- [ ] Add health check endpoints

### Phase 4: API Modernization (Week 7-8)
- [ ] Create RESTful API with versioning
- [ ] Add API authentication (JWT)
- [ ] Implement pagination
- [ ] Add API rate limiting
- [ ] Write API documentation (Swagger/OpenAPI)
- [ ] Add GraphQL endpoint (optional)

### Phase 5: Frontend Modernization (Week 9-12)
- [ ] Migrate to React or Vue.js
- [ ] Implement modern build system (Vite/Webpack)
- [ ] Add state management (Redux/Vuex)
- [ ] Implement responsive design
- [ ] Add Progressive Web App (PWA) features
- [ ] Improve accessibility (WCAG 2.1)

### Phase 6: Advanced Features (Week 13+)
- [ ] Implement WebSocket for real-time updates
- [ ] Add multi-language support (i18n)
- [ ] Implement advanced analytics
- [ ] Add email notifications
- [ ] Create mobile app (React Native/Flutter)
- [ ] Add blockchain explorers integration

---

## Maintenance Tasks

### Daily
- Monitor PM2 services: `pm2 monit`
- Check error logs: `pm2 logs --err --lines 100`
- Monitor disk space: `df -h`

### Weekly
- Review Apache logs: `sudo tail -500 /var/log/apache2/steemauto-error.log`
- Check MySQL slow queries
- Review system updates: `sudo apt update && sudo apt list --upgradable`
- Backup database: See backup script below

### Monthly
- Update dependencies: `npm outdated` and `npm update`
- Review SSL certificate expiry: `sudo certbot certificates`
- Analyze performance metrics
- Review and rotate logs

### Backup Script
```bash
#!/bin/bash
# Save as: /home/user/steemauto/scripts/backup.sh

BACKUP_DIR="/home/user/backups"
DATE=$(date +%Y%m%d_%H%M%S)
DB_USER="steemauto_user"
DB_NAME="steemauto"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup database
mysqldump -u $DB_USER -p$DB_PASSWORD $DB_NAME | gzip > $BACKUP_DIR/steemauto_db_$DATE.sql.gz

# Backup application files
tar -czf $BACKUP_DIR/steemauto_files_$DATE.tar.gz /home/user/steemauto \
    --exclude='node_modules' \
    --exclude='logs' \
    --exclude='.git'

# Keep only last 30 days of backups
find $BACKUP_DIR -name "steemauto_*" -mtime +30 -delete

echo "Backup completed: $DATE"
```

Make it executable:
```bash
chmod +x /home/user/steemauto/scripts/backup.sh
```

Add to crontab:
```bash
crontab -e
# Add this line for daily backup at 2 AM:
0 2 * * * /home/user/steemauto/scripts/backup.sh
```

---

## Support and Resources

### Documentation
- Steem API: https://developers.steem.io/
- PHP Documentation: https://www.php.net/docs.php
- Node.js Documentation: https://nodejs.org/docs/
- PM2 Documentation: https://pm2.keymetrics.io/docs/

### Monitoring Commands
```bash
# Quick health check
pm2 status && sudo systemctl status apache2 && sudo systemctl status mysql

# View all logs
tail -f /var/log/apache2/steemauto-error.log

# Database status
mysql -u steemauto_user -p steemauto -e "SHOW PROCESSLIST;"
```

---

## Conclusion

Your SteemAuto application should now be properly configured and running securely.

**Next Steps:**
1. Test all functionality thoroughly
2. Set up monitoring and alerts
3. Create a staging environment for testing updates
4. Begin Phase 1 of modernization plan

**Important Reminders:**
- Never commit `.env` file to git
- Regularly update dependencies
- Monitor logs for suspicious activity
- Keep backups and test restoration
- Document any customizations you make

Good luck with your SteemAuto deployment!
