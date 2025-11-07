# ZMAIL Installation Guide

This guide provides detailed step-by-step instructions for installing ZMAIL email server on Ubuntu 24.04.

## Table of Contents

1. [System Preparation](#system-preparation)
2. [DNS Configuration](#dns-configuration)
3. [Installation Process](#installation-process)
4. [Post-Installation Configuration](#post-installation-configuration)
5. [Verification](#verification)

## System Preparation

### 1. Update System

First, ensure your Ubuntu 24.04 system is up to date:

```bash
sudo apt update
sudo apt upgrade -y
sudo reboot
```

### 2. Set Hostname

Set your server's hostname to match your mail server domain:

```bash
sudo hostnamectl set-hostname mail.example.com
```

Edit `/etc/hosts`:

```bash
sudo nano /etc/hosts
```

Add:
```
127.0.0.1       localhost
127.0.1.1       mail.example.com mail
YOUR_SERVER_IP  mail.example.com mail
```

### 3. Set Timezone

```bash
sudo timedatectl set-timezone America/New_York
```

Replace `America/New_York` with your timezone.

## DNS Configuration

Configure the following DNS records with your domain registrar or DNS provider:

### Required Records

| Type | Name | Value | Priority | TTL |
|------|------|-------|----------|-----|
| A | mail.example.com | Your-Server-IP | - | 3600 |
| MX | example.com | mail.example.com | 10 | 3600 |
| TXT | example.com | v=spf1 mx ~all | - | 3600 |

### Optional but Recommended

**DKIM Record** (after installation):
```
Type: TXT
Name: default._domainkey.example.com
Value: (Generated during setup)
```

**DMARC Record**:
```
Type: TXT
Name: _dmarc.example.com
Value: v=DMARC1; p=none; rua=mailto:postmaster@example.com
```

**Reverse DNS (PTR)**:
Contact your hosting provider to set up reverse DNS:
```
Your-Server-IP → mail.example.com
```

### Verify DNS Propagation

Wait 10-30 minutes after making DNS changes, then verify:

```bash
# Check A record
dig A mail.example.com

# Check MX record
dig MX example.com

# Check TXT/SPF record
dig TXT example.com
```

## Installation Process

### Step 1: Clone Repository

```bash
cd /opt
sudo git clone https://github.com/cruvzadmin/ZMAIL.git
cd ZMAIL
```

### Step 2: Run Installation Script

```bash
sudo ./scripts/install.sh
```

During installation, you'll be prompted for:
- Your domain name (e.g., example.com)
- Your mail server hostname (e.g., mail.example.com)

The script will:
1. Install Postfix, Dovecot, MariaDB/MySQL
2. Install Certbot for SSL certificates
3. Configure UFW firewall
4. Create MySQL database structure
5. Backup original configuration files

### Step 3: Run Configuration Script

```bash
sudo ./scripts/configure.sh
```

You'll need to provide:
- Domain name
- Mail server hostname
- MySQL mailuser password (choose a strong password)

### Step 4: Generate SSL Certificates

Stop any web server that might be using port 80:

```bash
sudo systemctl stop nginx apache2 2>/dev/null || true
```

Generate certificates:

```bash
sudo certbot certonly --standalone -d mail.example.com
```

Follow the prompts:
- Enter your email address
- Accept terms of service
- Choose whether to share email with EFF

### Step 5: Set Certificate Permissions

```bash
sudo chmod 0755 /etc/letsencrypt/{live,archive}
sudo chmod 0644 /etc/letsencrypt/live/mail.example.com/fullchain.pem
sudo chmod 0644 /etc/letsencrypt/live/mail.example.com/privkey.pem
```

## Post-Installation Configuration

### 1. Verify Configuration Files

Check Postfix configuration:

```bash
sudo postfix check
```

Expected output: No errors (silence means success)

Check Dovecot configuration:

```bash
sudo doveconf -n
```

Expected output: Configuration summary without errors

### 2. Start and Enable Services

```bash
# Restart services
sudo systemctl restart postfix
sudo systemctl restart dovecot

# Enable services to start on boot
sudo systemctl enable postfix
sudo systemctl enable dovecot

# Check service status
sudo systemctl status postfix
sudo systemctl status dovecot
```

### 3. Configure Automatic Certificate Renewal

Certbot automatically creates a renewal cron job, but verify:

```bash
sudo certbot renew --dry-run
```

Add a renewal hook to reload services:

```bash
sudo bash -c 'cat > /etc/letsencrypt/renewal-hooks/deploy/reload-mail.sh << EOF
#!/bin/bash
systemctl reload postfix
systemctl reload dovecot
EOF'

sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-mail.sh
```

### 4. Create First Mail User

```bash
sudo ./scripts/manage-users.sh add-user admin@example.com SecurePassword123
```

### 5. Create Common Aliases

```bash
# Postmaster (required by RFC)
sudo ./scripts/manage-users.sh add-alias postmaster@example.com admin@example.com

# Abuse contact
sudo ./scripts/manage-users.sh add-alias abuse@example.com admin@example.com

# Webmaster
sudo ./scripts/manage-users.sh add-alias webmaster@example.com admin@example.com

# Info contact
sudo ./scripts/manage-users.sh add-alias info@example.com admin@example.com
```

## Verification

### 1. Test SMTP Connection

```bash
telnet mail.example.com 25
```

You should see:
```
220 mail.example.com ESMTP Postfix
```

Type `QUIT` to exit.

### 2. Test SMTP with TLS

```bash
openssl s_client -connect mail.example.com:587 -starttls smtp
```

You should see certificate information and:
```
250-mail.example.com
250-PIPELINING
250-SIZE 52428800
250-VRFY
250-ETRN
250-STARTTLS
250-AUTH PLAIN LOGIN
...
```

### 3. Test IMAP Connection

```bash
openssl s_client -connect mail.example.com:993
```

After connection, try logging in:
```
a1 LOGIN admin@example.com SecurePassword123
a2 LIST "" "*"
a3 LOGOUT
```

### 4. Send Test Email

From the server:

```bash
echo "This is a test email" | mail -s "Test from ZMAIL" admin@example.com
```

Check if received:

```bash
sudo ls -la /var/mail/vhosts/example.com/admin/new/
```

### 5. Test from External Client

Configure your email client (Thunderbird, Outlook, etc.) with:

**Incoming (IMAP)**:
- Server: mail.example.com
- Port: 993
- Security: SSL/TLS
- Username: admin@example.com
- Password: Your password

**Outgoing (SMTP)**:
- Server: mail.example.com
- Port: 587
- Security: STARTTLS
- Username: admin@example.com
- Password: Your password

### 6. Check Service Logs

Monitor for any errors:

```bash
# Watch mail logs in real-time
sudo tail -f /var/log/mail.log

# Check for errors
sudo grep -i error /var/log/mail.log
sudo grep -i warning /var/log/mail.log
```

## Troubleshooting Installation

### Issue: Port 25 is blocked

Many cloud providers block port 25 by default. Contact your provider to unblock it.

### Issue: SSL certificate error

Make sure:
1. Port 80 is open and not blocked
2. DNS A record points to correct IP
3. No web server is running on port 80

### Issue: Services won't start

Check logs:
```bash
sudo journalctl -xe
sudo journalctl -u postfix
sudo journalctl -u dovecot
```

### Issue: Cannot connect to MySQL

Check if MySQL is running:
```bash
sudo systemctl status mysql
sudo mysql -u mailuser -p mailserver
```

## Next Steps

1. **Set up DKIM**: See [DKIM Setup Guide](./dkim-setup.md)
2. **Configure Spam Filter**: See [Spam Filtering Guide](./spam-filtering.md)
3. **Set up Webmail**: Consider installing Roundcube or Rainloop
4. **Monitor Your Server**: Set up monitoring and alerts
5. **Test Email Deliverability**: Use mail-tester.com

## Security Hardening

See [Security Guide](./security-guide.md) for additional hardening steps.

## Support

If you encounter issues:
1. Check the logs in `/var/log/mail.log`
2. Review configuration with `postconf -n` and `doveconf -n`
3. Consult the troubleshooting section in the main README
4. Open an issue on GitHub

---

**Installation Complete!** Your ZMAIL email server is now ready to use.
