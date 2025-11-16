#!/bin/bash
#
# SteemAuto Installation Script
# This script automates the initial setup of SteemAuto
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}"
echo "========================================="
echo "   SteemAuto Installation Script"
echo "========================================="
echo -e "${NC}"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}This script should NOT be run as root${NC}"
   echo "Run it as a regular user with sudo privileges"
   exit 1
fi

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}➤ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."

    # Check Ubuntu version
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" ]] && [[ "$ID" != "debian" ]]; then
            print_error "This script is designed for Ubuntu/Debian"
            exit 1
        fi
    fi

    # Check internet connection
    if ! ping -c 1 google.com &> /dev/null; then
        print_error "No internet connection detected"
        exit 1
    fi

    print_success "Prerequisites check passed"
}

# Update system
update_system() {
    print_info "Updating system packages..."
    sudo apt update
    sudo apt upgrade -y
    print_success "System updated"
}

# Install required packages
install_packages() {
    print_info "Installing required packages..."

    # Apache2
    if ! command -v apache2 &> /dev/null; then
        sudo apt install apache2 -y
        print_success "Apache2 installed"
    else
        print_success "Apache2 already installed"
    fi

    # PHP
    if ! command -v php &> /dev/null; then
        sudo apt install php8.1 php8.1-cli php8.1-mysql php8.1-curl php8.1-mbstring php8.1-xml -y
        print_success "PHP installed"
    else
        print_success "PHP already installed"
    fi

    # MySQL
    if ! command -v mysql &> /dev/null; then
        sudo apt install mysql-server -y
        print_success "MySQL installed"
    else
        print_success "MySQL already installed"
    fi

    # Node.js
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt install nodejs -y
        print_success "Node.js installed"
    else
        print_success "Node.js already installed"
    fi

    # PM2
    if ! command -v pm2 &> /dev/null; then
        sudo npm install -g pm2
        print_success "PM2 installed"
    else
        print_success "PM2 already installed"
    fi

    # Git
    if ! command -v git &> /dev/null; then
        sudo apt install git -y
        print_success "Git installed"
    else
        print_success "Git already installed"
    fi

    # Certbot
    if ! command -v certbot &> /dev/null; then
        sudo apt install certbot python3-certbot-apache -y
        print_success "Certbot installed"
    else
        print_success "Certbot already installed"
    fi
}

# Setup Node.js dependencies
setup_nodejs() {
    print_info "Setting up Node.js dependencies..."

    cd /home/user/steemauto

    if [ ! -f package.json ]; then
        print_error "package.json not found!"
        exit 1
    fi

    npm install
    print_success "Node.js dependencies installed"
}

# Create necessary directories
create_directories() {
    print_info "Creating necessary directories..."

    cd /home/user/steemauto
    mkdir -p logs
    mkdir -p scripts
    mkdir -p backups

    print_success "Directories created"
}

# Setup environment file
setup_env() {
    print_info "Setting up environment configuration..."

    if [ -f /home/user/steemauto/.env ]; then
        print_info ".env file already exists. Skipping..."
        return
    fi

    read -p "Enter database password: " -s db_password
    echo
    read -p "Enter Steem posting private key (WIF): " -s steem_wif
    echo

    cat > /home/user/steemauto/.env << EOF
# Database Configuration
DB_HOST=127.0.0.1
DB_USER=steemauto_user
DB_PASSWORD=$db_password
DB_NAME=steemauto

# Steem Configuration
STEEM_WIF_KEY=$steem_wif
STEEM_RPC=wss://api.steemit.com
STEEM_RPC_HTTP=https://api.steemit.com

# Application Configuration
NODE_ENV=production
NODEJS_SERVER=http://127.0.0.1
UPVOTE_PORT=7412
EOF

    chmod 600 /home/user/steemauto/.env
    print_success "Environment file created"
}

# Setup database
setup_database() {
    print_info "Setting up database..."

    read -p "Enter MySQL root password: " -s mysql_root_password
    echo
    read -p "Enter database password for steemauto_user: " -s db_password
    echo

    # Create database and user
    mysql -u root -p$mysql_root_password << EOF
CREATE DATABASE IF NOT EXISTS steemauto CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'steemauto_user'@'localhost' IDENTIFIED BY '$db_password';
GRANT ALL PRIVILEGES ON steemauto.* TO 'steemauto_user'@'localhost';
FLUSH PRIVILEGES;
EOF

    # Import schema
    if [ -f /home/user/steemauto/mysql.sql ]; then
        mysql -u steemauto_user -p$db_password steemauto < /home/user/steemauto/mysql.sql
        print_success "Database setup completed"
    else
        print_error "mysql.sql not found!"
        exit 1
    fi
}

# Setup Apache
setup_apache() {
    print_info "Setting up Apache..."

    read -p "Enter your domain name (or press Enter for localhost): " domain_name
    domain_name=${domain_name:-localhost}

    sudo cat > /etc/apache2/sites-available/steemauto.conf << EOF
<VirtualHost *:80>
    ServerAdmin admin@$domain_name
    ServerName $domain_name
    DocumentRoot /home/user/steemauto

    <Directory /home/user/steemauto>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    <Directory /home/user/steemauto/inc>
        Require all denied
    </Directory>

    <Directory /home/user/steemauto/nodejs>
        Require all denied
    </Directory>

    <Directory /home/user/steemauto/.git>
        Require all denied
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/steemauto-error.log
    CustomLog \${APACHE_LOG_DIR}/steemauto-access.log combined

    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
</VirtualHost>
EOF

    sudo a2enmod rewrite
    sudo a2enmod headers
    sudo a2ensite steemauto.conf
    sudo a2dissite 000-default.conf
    sudo apache2ctl configtest
    sudo systemctl restart apache2

    print_success "Apache configured"
}

# Set permissions
set_permissions() {
    print_info "Setting file permissions..."

    cd /home/user/steemauto
    sudo chown -R www-data:www-data .
    find . -type d -exec chmod 755 {} \;
    find . -type f -exec chmod 644 {} \;
    chmod 600 .env
    chmod 755 logs

    print_success "Permissions set"
}

# Setup firewall
setup_firewall() {
    print_info "Setting up firewall..."

    sudo apt install ufw -y
    sudo ufw allow 22/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    echo "y" | sudo ufw enable

    print_success "Firewall configured"
}

# Main installation flow
main() {
    echo
    print_info "Starting installation..."
    echo

    check_prerequisites

    read -p "Update system packages? (y/n): " update_choice
    if [[ $update_choice == "y" ]]; then
        update_system
    fi

    install_packages
    create_directories

    read -p "Setup environment file? (y/n): " env_choice
    if [[ $env_choice == "y" ]]; then
        setup_env
    fi

    read -p "Setup database? (y/n): " db_choice
    if [[ $db_choice == "y" ]]; then
        setup_database
    fi

    setup_nodejs

    read -p "Setup Apache? (y/n): " apache_choice
    if [[ $apache_choice == "y" ]]; then
        setup_apache
    fi

    set_permissions

    read -p "Setup firewall? (y/n): " firewall_choice
    if [[ $firewall_choice == "y" ]]; then
        setup_firewall
    fi

    echo
    echo -e "${GREEN}"
    echo "========================================="
    echo "   Installation Complete!"
    echo "========================================="
    echo -e "${NC}"
    echo
    echo "Next steps:"
    echo "1. Start services: cd /home/user/steemauto && pm2 start ecosystem.config.js"
    echo "2. Save PM2 config: pm2 save"
    echo "3. Setup PM2 startup: pm2 startup systemd"
    echo "4. Visit your site in a browser"
    echo
    echo "For detailed instructions, see SETUP_GUIDE.md"
    echo
}

# Run main function
main
