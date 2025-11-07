# ZMAIL Quick Start Guide

Get your email server up and running in 15 minutes!

## Prerequisites Checklist

Before you begin, ensure you have:

- [ ] Ubuntu 24.04 LTS server with root access
- [ ] At least 1GB RAM (2GB recommended)
- [ ] A registered domain name (e.g., example.com)
- [ ] DNS access to configure records
- [ ] Server IP address (static)

## Step 1: Configure DNS (5 minutes)

Add these DNS records at your domain registrar:

| Type | Name | Value | Priority |
|------|------|-------|----------|
| A | mail.example.com | YOUR_SERVER_IP | - |
| MX | example.com | mail.example.com | 10 |
| TXT | example.com | v=spf1 mx ~all | - |

**Wait 10-15 minutes** for DNS to propagate before continuing.

## Step 2: Install ZMAIL (3 minutes)

```bash
# Clone repository
cd /opt
sudo git clone https://github.com/cruvzadmin/ZMAIL.git
cd ZMAIL

# Run installation
sudo ./scripts/install.sh
```

When prompted, enter:
- Your domain: `example.com`
- Your hostname: `mail.example.com`

## Step 3: Configure Server (2 minutes)

```bash
sudo ./scripts/configure.sh
```

When prompted, enter:
- Domain: `example.com`
- Hostname: `mail.example.com`
- MySQL password: Choose a strong password and save it!

## Step 4: Get SSL Certificate (3 minutes)

```bash
# Stop any conflicting web servers
sudo systemctl stop nginx apache2 2>/dev/null || true

# Get certificate
sudo certbot certonly --standalone -d mail.example.com

# Start mail services
sudo systemctl restart postfix dovecot
sudo systemctl enable postfix dovecot
```

## Step 5: Create Users (2 minutes)

```bash
# Create your first email account
sudo ./scripts/manage-users.sh add-user admin@example.com YourPassword123

# Create common aliases
sudo ./scripts/manage-users.sh add-alias postmaster@example.com admin@example.com
sudo ./scripts/manage-users.sh add-alias info@example.com admin@example.com
```

## Step 6: Test Your Server (2 minutes)

### Test SMTP

```bash
telnet mail.example.com 25
# You should see: 220 mail.example.com ESMTP Postfix
# Type: QUIT
```

### Test IMAP

```bash
openssl s_client -connect mail.example.com:993
# After connection, type:
# a1 LOGIN admin@example.com YourPassword123
# a2 LIST "" "*"
# a3 LOGOUT
```

### Send Test Email

```bash
echo "Test email body" | mail -s "Test" admin@example.com
```

## Step 7: Configure Email Client

Use these settings in your email client (Thunderbird, Outlook, etc.):

**Incoming Mail (IMAP)**
- Server: mail.example.com
- Port: 993
- Security: SSL/TLS
- Username: admin@example.com
- Password: YourPassword123

**Outgoing Mail (SMTP)**
- Server: mail.example.com
- Port: 587
- Security: STARTTLS
- Username: admin@example.com
- Password: YourPassword123

## Verification Checklist

- [ ] DNS records configured and propagated
- [ ] ZMAIL installed successfully
- [ ] SSL certificate obtained
- [ ] Services running (postfix, dovecot)
- [ ] Email account created
- [ ] SMTP test successful
- [ ] IMAP test successful
- [ ] Email client configured and working

## Common Issues

### Cannot get SSL certificate
- Ensure port 80 is open
- Check DNS A record points to correct IP
- Wait longer for DNS propagation

### Cannot send email
- Check if port 25 is blocked by your ISP
- Verify firewall allows port 587
- Check logs: `sudo tail -f /var/log/mail.log`

### Cannot receive email
- Check MX record in DNS
- Verify domain in database: `sudo mysql mailserver -e "SELECT * FROM virtual_domains;"`
- Check Dovecot status: `sudo systemctl status dovecot`

## Next Steps

Now that your email server is running:

1. **Add more users**: `sudo ./scripts/manage-users.sh add-user user@example.com password`
2. **Set up DKIM**: Improve email deliverability (see docs/SECURITY.md)
3. **Monitor your server**: Check logs regularly
4. **Test email deliverability**: Use https://www.mail-tester.com/
5. **Set up backups**: Backup your database and mail directories

## Need Help?

- Check the full documentation in `README.md`
- Review installation guide: `docs/INSTALLATION.md`
- Security guide: `docs/SECURITY.md`
- Check logs: `/var/log/mail.log`

---

**Congratulations!** Your ZMAIL email server is now operational! 🎉
