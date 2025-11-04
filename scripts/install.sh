#!/bin/bash

# ZMAIL - Email Server Installation Script for Ubuntu 24.04
# This script installs and configures a complete email server with Postfix and Dovecot

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root or with sudo"
   exit 1
fi

# Check Ubuntu version
if ! grep -q "24.04" /etc/lsb-release 2>/dev/null; then
    log_warn "This script is designed for Ubuntu 24.04. Your version may differ."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Get domain and hostname from user
log_info "Starting ZMAIL Email Server installation..."
echo ""
read -p "Enter your domain name (e.g., example.com): " DOMAIN
read -p "Enter your mail server hostname (e.g., mail.example.com): " HOSTNAME

# Validate inputs
if [ -z "$DOMAIN" ] || [ -z "$HOSTNAME" ]; then
    log_error "Domain and hostname cannot be empty"
    exit 1
fi

log_info "Domain: $DOMAIN"
log_info "Hostname: $HOSTNAME"
echo ""
read -p "Is this correct? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_error "Installation cancelled"
    exit 1
fi

# Update system
log_info "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install required packages
log_info "Installing Postfix (SMTP server)..."
DEBIAN_FRONTEND=noninteractive apt-get install -y postfix postfix-mysql

log_info "Installing Dovecot (IMAP/POP3 server)..."
apt-get install -y dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql

log_info "Installing additional required packages..."
apt-get install -y mariadb-server certbot python3-certbot-nginx nginx ufw fail2ban

# Configure hostname
log_info "Configuring hostname..."
hostnamectl set-hostname "$HOSTNAME"
echo "$HOSTNAME" > /etc/hostname

# Update /etc/hosts
if ! grep -q "$HOSTNAME" /etc/hosts; then
    echo "127.0.1.1 $HOSTNAME" >> /etc/hosts
fi

# Configure firewall
log_info "Configuring firewall..."
ufw --force enable
ufw allow 22/tcp    # SSH
ufw allow 25/tcp    # SMTP
ufw allow 587/tcp   # Submission
ufw allow 465/tcp   # SMTPS
ufw allow 993/tcp   # IMAPS
ufw allow 995/tcp   # POP3S
ufw allow 80/tcp    # HTTP (for certbot)
ufw allow 443/tcp   # HTTPS

log_info "Firewall configured successfully"

# Setup MySQL database for mail users
log_info "Setting up MySQL database..."
mysql -e "CREATE DATABASE IF NOT EXISTS mailserver;"
mysql -e "CREATE USER IF NOT EXISTS 'mailuser'@'localhost' IDENTIFIED BY '$(openssl rand -base64 32)';"
mysql -e "GRANT ALL PRIVILEGES ON mailserver.* TO 'mailuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Create database tables
mysql mailserver << EOF
CREATE TABLE IF NOT EXISTS virtual_domains (
    id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS virtual_users (
    id INT NOT NULL AUTO_INCREMENT,
    domain_id INT NOT NULL,
    password VARCHAR(106) NOT NULL,
    email VARCHAR(100) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY email (email),
    FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS virtual_aliases (
    id INT NOT NULL AUTO_INCREMENT,
    domain_id INT NOT NULL,
    source VARCHAR(100) NOT NULL,
    destination VARCHAR(100) NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOF

# Insert the domain
mysql mailserver -e "INSERT INTO virtual_domains (name) VALUES ('$DOMAIN');"

log_info "Database setup completed"

# Backup original configurations
log_info "Backing up original configuration files..."
cp /etc/postfix/main.cf /etc/postfix/main.cf.backup
cp /etc/postfix/master.cf /etc/postfix/master.cf.backup
cp /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.backup

log_info "Installation completed successfully!"
echo ""
log_info "Next steps:"
echo "1. Configure Postfix using the config files in config/postfix/"
echo "2. Configure Dovecot using the config files in config/dovecot/"
echo "3. Generate SSL certificates using: certbot certonly --standalone -d $HOSTNAME"
echo "4. Create mail users using the user management script"
echo "5. Test your email server configuration"
echo ""
log_warn "Please review and customize the configuration files before starting the services"
