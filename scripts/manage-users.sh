#!/bin/bash

# ZMAIL - User Management Script
# Add, delete, and list mail users

set -e

MYSQL_USER="mailuser"
MYSQL_DB="mailserver"

# Colors
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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root or with sudo"
   exit 1
fi

show_usage() {
    echo "ZMAIL User Management"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  add-user <email> <password>    Add a new mail user"
    echo "  delete-user <email>             Delete a mail user"
    echo "  list-users                      List all mail users"
    echo "  change-password <email> <new_password>  Change user password"
    echo "  add-alias <source> <destination>         Add email alias"
    echo "  delete-alias <source>                    Delete email alias"
    echo "  list-aliases                             List all aliases"
    echo ""
    echo "Examples:"
    echo "  $0 add-user user@example.com MySecurePassword123"
    echo "  $0 delete-user user@example.com"
    echo "  $0 list-users"
    echo "  $0 add-alias info@example.com user@example.com"
    echo ""
}

add_user() {
    local email=$1
    local password=$2
    
    if [ -z "$email" ] || [ -z "$password" ]; then
        log_error "Email and password are required"
        exit 1
    fi
    
    # Extract domain from email
    local domain=$(echo $email | cut -d'@' -f2)
    
    # Check if domain exists
    local domain_id=$(mysql -N -s $MYSQL_DB -e "SELECT id FROM virtual_domains WHERE name='$domain'")
    
    if [ -z "$domain_id" ]; then
        log_error "Domain $domain does not exist in the database"
        exit 1
    fi
    
    # Hash the password using SHA512-CRYPT
    local hashed_password=$(doveadm pw -s SHA512-CRYPT -p "$password")
    
    # Insert user
    mysql $MYSQL_DB -e "INSERT INTO virtual_users (domain_id, email, password) VALUES ($domain_id, '$email', '$hashed_password')"
    
    # Create mail directory
    local mail_dir="/var/mail/vhosts/$domain/${email%%@*}"
    mkdir -p "$mail_dir"
    chown -R vmail:vmail "/var/mail/vhosts/$domain"
    chmod -R 770 "/var/mail/vhosts/$domain"
    
    log_info "User $email created successfully"
}

delete_user() {
    local email=$1
    
    if [ -z "$email" ]; then
        log_error "Email is required"
        exit 1
    fi
    
    # Delete user from database
    mysql $MYSQL_DB -e "DELETE FROM virtual_users WHERE email='$email'"
    
    log_info "User $email deleted successfully"
    log_warn "Mail data in /var/mail/vhosts/ was not deleted. Remove manually if needed."
}

list_users() {
    log_info "Listing all mail users:"
    echo ""
    mysql $MYSQL_DB -e "SELECT u.email, d.name as domain FROM virtual_users u JOIN virtual_domains d ON u.domain_id = d.id ORDER BY d.name, u.email"
}

change_password() {
    local email=$1
    local new_password=$2
    
    if [ -z "$email" ] || [ -z "$new_password" ]; then
        log_error "Email and new password are required"
        exit 1
    fi
    
    # Hash the password
    local hashed_password=$(doveadm pw -s SHA512-CRYPT -p "$new_password")
    
    # Update password
    mysql $MYSQL_DB -e "UPDATE virtual_users SET password='$hashed_password' WHERE email='$email'"
    
    log_info "Password for $email changed successfully"
}

add_alias() {
    local source=$1
    local destination=$2
    
    if [ -z "$source" ] || [ -z "$destination" ]; then
        log_error "Source and destination are required"
        exit 1
    fi
    
    # Extract domain from source
    local domain=$(echo $source | cut -d'@' -f2)
    
    # Check if domain exists
    local domain_id=$(mysql -N -s $MYSQL_DB -e "SELECT id FROM virtual_domains WHERE name='$domain'")
    
    if [ -z "$domain_id" ]; then
        log_error "Domain $domain does not exist in the database"
        exit 1
    fi
    
    # Insert alias
    mysql $MYSQL_DB -e "INSERT INTO virtual_aliases (domain_id, source, destination) VALUES ($domain_id, '$source', '$destination')"
    
    log_info "Alias $source -> $destination created successfully"
}

delete_alias() {
    local source=$1
    
    if [ -z "$source" ]; then
        log_error "Source email is required"
        exit 1
    fi
    
    # Delete alias
    mysql $MYSQL_DB -e "DELETE FROM virtual_aliases WHERE source='$source'"
    
    log_info "Alias $source deleted successfully"
}

list_aliases() {
    log_info "Listing all email aliases:"
    echo ""
    mysql $MYSQL_DB -e "SELECT a.source, a.destination, d.name as domain FROM virtual_aliases a JOIN virtual_domains d ON a.domain_id = d.id ORDER BY d.name, a.source"
}

# Main script logic
case "$1" in
    add-user)
        add_user "$2" "$3"
        ;;
    delete-user)
        delete_user "$2"
        ;;
    list-users)
        list_users
        ;;
    change-password)
        change_password "$2" "$3"
        ;;
    add-alias)
        add_alias "$2" "$3"
        ;;
    delete-alias)
        delete_alias "$2"
        ;;
    list-aliases)
        list_aliases
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
