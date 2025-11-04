#!/bin/bash

# ZMAIL - Configuration Setup Script
# This script sets up the configuration files after installation

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root or with sudo"
   exit 1
fi

# Get configuration values
echo "ZMAIL Email Server Configuration"
echo "================================="
echo ""
read -p "Enter your domain name (e.g., example.com): " DOMAIN
read -p "Enter your mail server hostname (e.g., mail.example.com): " HOSTNAME
read -p "Enter MySQL mailuser password: " -s MYSQL_PASSWORD
echo ""

if [ -z "$DOMAIN" ] || [ -z "$HOSTNAME" ] || [ -z "$MYSQL_PASSWORD" ]; then
    log_error "All fields are required"
    exit 1
fi

log_info "Configuring ZMAIL with:"
echo "  Domain: $DOMAIN"
echo "  Hostname: $HOSTNAME"
echo ""

# Create vmail user if it doesn't exist
if ! id -u vmail > /dev/null 2>&1; then
    log_info "Creating vmail user..."
    groupadd -g 5000 vmail
    useradd -g vmail -u 5000 vmail -d /var/mail -s /usr/sbin/nologin
fi

# Create mail directories
log_info "Creating mail directories..."
mkdir -p /var/mail/vhosts/$DOMAIN
chown -R vmail:vmail /var/mail
chmod -R 770 /var/mail

# Copy Postfix configuration files
log_info "Configuring Postfix..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"

cp "$CONFIG_DIR/postfix/main.cf" /etc/postfix/main.cf
cp "$CONFIG_DIR/postfix/master.cf" /etc/postfix/master.cf
cp "$CONFIG_DIR/postfix/mysql-virtual-mailbox-domains.cf" /etc/postfix/
cp "$CONFIG_DIR/postfix/mysql-virtual-mailbox-maps.cf" /etc/postfix/
cp "$CONFIG_DIR/postfix/mysql-virtual-alias-maps.cf" /etc/postfix/

# Update configuration files with actual values
sed -i "s/mail.example.com/$HOSTNAME/g" /etc/postfix/main.cf
sed -i "s/example.com/$DOMAIN/g" /etc/postfix/main.cf

sed -i "s/CHANGE_THIS_PASSWORD/$MYSQL_PASSWORD/g" /etc/postfix/mysql-virtual-mailbox-domains.cf
sed -i "s/CHANGE_THIS_PASSWORD/$MYSQL_PASSWORD/g" /etc/postfix/mysql-virtual-mailbox-maps.cf
sed -i "s/CHANGE_THIS_PASSWORD/$MYSQL_PASSWORD/g" /etc/postfix/mysql-virtual-alias-maps.cf

# Set proper permissions for MySQL config files
chmod 640 /etc/postfix/mysql-*.cf
chown root:postfix /etc/postfix/mysql-*.cf

# Copy Dovecot configuration files
log_info "Configuring Dovecot..."
mkdir -p /etc/dovecot/conf.d

cp "$CONFIG_DIR/dovecot/dovecot.conf" /etc/dovecot/
cp "$CONFIG_DIR/dovecot/10-auth.conf" /etc/dovecot/conf.d/
cp "$CONFIG_DIR/dovecot/10-mail.conf" /etc/dovecot/conf.d/
cp "$CONFIG_DIR/dovecot/10-master.conf" /etc/dovecot/conf.d/
cp "$CONFIG_DIR/dovecot/10-ssl.conf" /etc/dovecot/conf.d/
cp "$CONFIG_DIR/dovecot/dovecot-sql.conf.ext" /etc/dovecot/

# Update Dovecot configuration with actual values
sed -i "s/mail.example.com/$HOSTNAME/g" /etc/dovecot/conf.d/10-ssl.conf
sed -i "s/CHANGE_THIS_PASSWORD/$MYSQL_PASSWORD/g" /etc/dovecot/dovecot-sql.conf.ext

# Set proper permissions
chmod 640 /etc/dovecot/dovecot-sql.conf.ext
chown root:dovecot /etc/dovecot/dovecot-sql.conf.ext

# Generate DH parameters if not exists
if [ ! -f /etc/dovecot/dh.pem ]; then
    log_info "Generating Diffie-Hellman parameters (this may take a while)..."
    openssl dhparam -out /etc/dovecot/dh.pem 2048
fi

# Update MySQL password
log_info "Updating MySQL password..."
mysql -e "ALTER USER 'mailuser'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';"
mysql -e "FLUSH PRIVILEGES;"

log_info "Configuration completed successfully!"
echo ""
log_warn "IMPORTANT NEXT STEPS:"
echo "1. Generate SSL certificates:"
echo "   certbot certonly --standalone -d $HOSTNAME"
echo ""
echo "2. After obtaining certificates, restart services:"
echo "   systemctl restart postfix"
echo "   systemctl restart dovecot"
echo ""
echo "3. Enable services to start on boot:"
echo "   systemctl enable postfix"
echo "   systemctl enable dovecot"
echo ""
echo "4. Create mail users:"
echo "   ./scripts/manage-users.sh add-user user@$DOMAIN password"
echo ""
echo "5. Test your configuration:"
echo "   postfix check"
echo "   doveconf -n"
echo ""
