# ZMAIL - Email Server for Ubuntu 24.04

A complete, production-ready email server solution for Ubuntu 24.04 LTS featuring Postfix (SMTP) and Dovecot (IMAP/POP3).

## Features

- ✉️ **Full Email Server**: Complete SMTP, IMAP, and POP3 support
- 🔒 **Secure by Default**: TLS/SSL encryption, modern cipher suites
- 📊 **MySQL Backend**: User and domain management with database
- 🛡️ **Security Hardened**: Fail2ban, UFW firewall, spam filtering
- 👥 **Multi-Domain Support**: Host multiple domains on one server
- 📝 **Easy Management**: Simple scripts for user and alias management
- 🔐 **Let's Encrypt**: Free SSL certificates integration

## Architecture

```
┌─────────────────────────────────────────────┐
│            Internet                          │
└──────────────┬──────────────────────────────┘
               │
        ┌──────▼───────┐
        │   Firewall   │  Ports: 25, 587, 465, 993, 995
        │     (UFW)    │
        └──────┬───────┘
               │
        ┌──────▼───────┐
        │   Postfix    │  SMTP Server (sending/receiving)
        │   (SMTP)     │
        └──────┬───────┘
               │
        ┌──────▼───────┐
        │   Dovecot    │  IMAP/POP3 Server (mailbox access)
        │  (IMAP/POP3) │
        └──────┬───────┘
               │
        ┌──────▼───────┐
        │    MySQL     │  User & Domain Database
        └──────────────┘
```

## System Requirements

- **OS**: Ubuntu 24.04 LTS (64-bit)
- **RAM**: Minimum 1GB (2GB recommended)
- **Disk**: At least 10GB free space
- **Domain**: A registered domain name with DNS access
- **Root Access**: Required for installation

## Prerequisites

Before installing, ensure you have:

1. **Domain Name**: A registered domain (e.g., example.com)
2. **DNS Records**: Configure the following DNS records:
   ```
   A     mail.example.com    →  Your-Server-IP
   MX    example.com         →  mail.example.com (Priority: 10)
   TXT   example.com         →  "v=spf1 mx ~all"
   ```
3. **Server Access**: Root or sudo access to Ubuntu 24.04 server
4. **Open Ports**: Ensure ports 25, 587, 465, 993, 995 are accessible

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/cruvzadmin/ZMAIL.git
cd ZMAIL
```

### 2. Run Installation

```bash
sudo ./scripts/install.sh
```

The installer will:
- Update system packages
- Install Postfix, Dovecot, MySQL, and dependencies
- Configure firewall (UFW)
- Create MySQL database for mail users
- Set up initial directory structure

### 3. Configure the Server

```bash
sudo ./scripts/configure.sh
```

This will:
- Set up Postfix and Dovecot configuration files
- Configure virtual domain support
- Create mail directories with proper permissions
- Apply your domain settings

### 4. Generate SSL Certificates

```bash
sudo certbot certonly --standalone -d mail.example.com
```

### 5. Start Services

```bash
sudo systemctl restart postfix
sudo systemctl restart dovecot
sudo systemctl enable postfix
sudo systemctl enable dovecot
```

### 6. Create Your First User

```bash
sudo ./scripts/manage-users.sh add-user user@example.com SecurePassword123
```

## Configuration

### Postfix Configuration

Main configuration: `/etc/postfix/main.cf`

Key settings:
- **myhostname**: Your mail server hostname (mail.example.com)
- **mydomain**: Your primary domain (example.com)
- **virtual_mailbox_domains**: MySQL query for virtual domains
- **TLS Settings**: Strong encryption with modern protocols

### Dovecot Configuration

Main configuration: `/etc/dovecot/dovecot.conf`

Key settings:
- **protocols**: imap, pop3, lmtp
- **mail_location**: Maildir format in /var/mail/vhosts/
- **SSL**: Required for all connections
- **Authentication**: MySQL-based user database

### MySQL Database

Database: `mailserver`

Tables:
- **virtual_domains**: Stores domain names
- **virtual_users**: Mail user accounts with hashed passwords
- **virtual_aliases**: Email aliases and forwarding

## User Management

### Add a User

```bash
sudo ./scripts/manage-users.sh add-user email@example.com password
```

### Delete a User

```bash
sudo ./scripts/manage-users.sh delete-user email@example.com
```

### List All Users

```bash
sudo ./scripts/manage-users.sh list-users
```

### Change Password

```bash
sudo ./scripts/manage-users.sh change-password email@example.com newpassword
```

### Add Email Alias

```bash
sudo ./scripts/manage-users.sh add-alias info@example.com user@example.com
```

### List Aliases

```bash
sudo ./scripts/manage-users.sh list-aliases
```

## Testing

### Test SMTP (Sending)

```bash
# Test if Postfix is accepting connections
telnet mail.example.com 25

# Test submission port (authenticated)
openssl s_client -connect mail.example.com:587 -starttls smtp
```

### Test IMAP (Receiving)

```bash
# Test IMAP SSL
openssl s_client -connect mail.example.com:993

# Login and check mailbox
a1 LOGIN user@example.com password
a2 LIST "" "*"
a3 SELECT INBOX
a4 LOGOUT
```

### Check Configuration

```bash
# Verify Postfix configuration
sudo postfix check

# Test Postfix configuration
sudo postconf -n

# Verify Dovecot configuration
sudo doveconf -n

# Check if services are running
sudo systemctl status postfix
sudo systemctl status dovecot
```

### Send Test Email

```bash
echo "Test email body" | mail -s "Test Subject" recipient@example.com
```

## Security

### Firewall Rules

The installation automatically configures UFW with:
- Port 22 (SSH)
- Port 25 (SMTP)
- Port 587 (Submission)
- Port 465 (SMTPS)
- Port 993 (IMAPS)
- Port 995 (POP3S)
- Port 80/443 (HTTP/HTTPS for Let's Encrypt)

### Fail2ban Protection

Fail2ban is installed to protect against brute-force attacks. Configuration file: `/etc/fail2ban/jail.local`

### SSL/TLS

- **Minimum TLS**: TLS 1.2
- **Ciphers**: Modern, secure cipher suites only
- **Certificates**: Let's Encrypt free certificates
- **Auto-renewal**: Configured via certbot

### Password Security

- Passwords are hashed using SHA512-CRYPT
- Plaintext authentication is disabled
- SASL authentication required for sending

## Monitoring

### View Mail Logs

```bash
# Postfix logs
sudo tail -f /var/log/mail.log

# Dovecot logs
sudo tail -f /var/log/dovecot.log

# System logs
sudo journalctl -u postfix -f
sudo journalctl -u dovecot -f
```

### Check Mail Queue

```bash
# View mail queue
sudo postqueue -p

# Flush mail queue
sudo postqueue -f
```

### Monitor Disk Usage

```bash
# Check mail directory size
sudo du -sh /var/mail/vhosts/*
```

## Troubleshooting

### Common Issues

#### 1. Cannot Send Email

**Problem**: SMTP connection refused

**Solution**:
```bash
sudo systemctl status postfix
sudo postfix check
sudo tail -f /var/log/mail.log
```

#### 2. Cannot Receive Email

**Problem**: Mail not arriving in inbox

**Solution**:
```bash
# Check if Dovecot is running
sudo systemctl status dovecot

# Check permissions
sudo ls -la /var/mail/vhosts/

# Verify user exists
sudo ./scripts/manage-users.sh list-users
```

#### 3. SSL Certificate Issues

**Problem**: Certificate errors

**Solution**:
```bash
# Renew certificates
sudo certbot renew

# Check certificate files
sudo ls -la /etc/letsencrypt/live/mail.example.com/

# Restart services
sudo systemctl restart postfix dovecot
```

#### 4. Authentication Failures

**Problem**: Cannot login to email account

**Solution**:
```bash
# Check MySQL connection
sudo mysql mailserver -e "SELECT * FROM virtual_users;"

# Test Dovecot authentication
sudo doveadm auth test user@example.com password

# Check Dovecot logs
sudo tail -f /var/log/dovecot.log
```

### DNS Verification

```bash
# Check MX records
dig MX example.com

# Check A record
dig A mail.example.com

# Check SPF record
dig TXT example.com
```

## Maintenance

### Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### Backup Database

```bash
sudo mysqldump mailserver > mailserver-backup-$(date +%Y%m%d).sql
```

### Renew SSL Certificates

Certificates auto-renew, but you can manually renew:

```bash
sudo certbot renew
```

### Clean Up Old Logs

```bash
sudo journalctl --vacuum-time=30d
```

## Advanced Configuration

### Add Multiple Domains

```bash
# Add domain to database
sudo mysql mailserver -e "INSERT INTO virtual_domains (name) VALUES ('newdomain.com');"

# Create users for the new domain
sudo ./scripts/manage-users.sh add-user user@newdomain.com password
```

### Spam Filtering (Optional)

Install SpamAssassin:

```bash
sudo apt install spamassassin spamc
sudo systemctl enable spamassassin
sudo systemctl start spamassassin
```

### Antivirus (Optional)

Install ClamAV:

```bash
sudo apt install clamav clamav-daemon
sudo freshclam
sudo systemctl enable clamav-daemon
sudo systemctl start clamav-daemon
```

## Performance Tuning

### For High Volume

Edit `/etc/postfix/main.cf`:

```
default_process_limit = 100
smtpd_client_connection_count_limit = 10
smtpd_client_connection_rate_limit = 30
```

### Optimize MySQL

Edit `/etc/mysql/my.cnf`:

```
[mysqld]
innodb_buffer_pool_size = 256M
query_cache_size = 32M
```

## Support

- **Documentation**: See `docs/` folder for detailed guides
- **Issues**: Report bugs on GitHub Issues
- **Email**: Contact system administrator

## License

This project is open source and available for use in production environments.

## Credits

- **Postfix**: http://www.postfix.org/
- **Dovecot**: https://www.dovecot.org/
- **Let's Encrypt**: https://letsencrypt.org/

## Version

- **ZMAIL**: 1.0.0
- **Target OS**: Ubuntu 24.04 LTS
- **Last Updated**: 2024

---

**Note**: Always test configuration changes in a development environment before applying to production.
