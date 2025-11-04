# ZMAIL Troubleshooting Guide

Common issues and their solutions for ZMAIL email server.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Service Issues](#service-issues)
3. [Email Sending Issues](#email-sending-issues)
4. [Email Receiving Issues](#email-receiving-issues)
5. [Authentication Issues](#authentication-issues)
6. [SSL/TLS Issues](#ssltls-issues)
7. [Performance Issues](#performance-issues)
8. [Database Issues](#database-issues)

## Installation Issues

### Issue: Package installation fails

**Symptoms**: `apt-get install` fails during installation

**Solution**:
```bash
# Update package lists
sudo apt update

# Fix broken packages
sudo apt --fix-broken install

# Retry installation
sudo ./scripts/install.sh
```

### Issue: Permission denied errors

**Symptoms**: Script fails with "Permission denied"

**Solution**:
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run with sudo
sudo ./scripts/install.sh
```

### Issue: Port 25 blocked

**Symptoms**: Cannot send/receive email on port 25

**Solution**:
- Check with your hosting provider
- Use port 587 for submission instead
- Test: `telnet mail.example.com 25`

## Service Issues

### Issue: Postfix won't start

**Symptoms**: `systemctl start postfix` fails

**Diagnosis**:
```bash
# Check status
sudo systemctl status postfix

# Check configuration
sudo postfix check

# View detailed logs
sudo journalctl -u postfix -n 50
```

**Common Solutions**:

1. **Configuration error**:
   ```bash
   sudo postfix check
   # Fix any errors shown
   ```

2. **Port already in use**:
   ```bash
   sudo netstat -tlnp | grep :25
   # Kill process using port 25
   ```

3. **Missing files/permissions**:
   ```bash
   sudo chown -R postfix:postfix /var/spool/postfix
   sudo chmod 755 /var/spool/postfix
   ```

### Issue: Dovecot won't start

**Symptoms**: `systemctl start dovecot` fails

**Diagnosis**:
```bash
# Check status
sudo systemctl status dovecot

# Check configuration
sudo doveconf -n

# View logs
sudo journalctl -u dovecot -n 50
```

**Common Solutions**:

1. **Configuration error**:
   ```bash
   sudo doveconf -n
   # Look for "Error:" lines
   ```

2. **SSL certificate missing**:
   ```bash
   # Check if certificates exist
   ls -la /etc/letsencrypt/live/mail.example.com/
   
   # Regenerate if needed
   sudo certbot certonly --standalone -d mail.example.com
   ```

3. **Permission issues**:
   ```bash
   sudo chown -R vmail:vmail /var/mail
   sudo chmod -R 770 /var/mail
   ```

## Email Sending Issues

### Issue: Cannot send email

**Symptoms**: Email client shows "Connection refused" or "Cannot connect to SMTP"

**Diagnosis**:
```bash
# Test SMTP connection
telnet mail.example.com 587

# Check Postfix is running
sudo systemctl status postfix

# Check firewall
sudo ufw status

# View mail logs
sudo tail -f /var/log/mail.log
```

**Solutions**:

1. **Firewall blocking**:
   ```bash
   sudo ufw allow 587/tcp
   sudo ufw allow 25/tcp
   ```

2. **Service not running**:
   ```bash
   sudo systemctl restart postfix
   ```

3. **Authentication failing**:
   ```bash
   # Check SASL is configured
   sudo postconf -n | grep sasl
   
   # Test authentication
   sudo doveadm auth test user@example.com password
   ```

### Issue: Emails stuck in queue

**Symptoms**: `postqueue -p` shows messages

**Diagnosis**:
```bash
# View queue
sudo postqueue -p

# View specific message
sudo postcat -q MESSAGE_ID

# Check logs
sudo grep MESSAGE_ID /var/log/mail.log
```

**Solutions**:

1. **Temporary failure - retry**:
   ```bash
   sudo postqueue -f
   ```

2. **Permanent failure - delete**:
   ```bash
   sudo postsuper -d MESSAGE_ID
   
   # Delete all
   sudo postsuper -d ALL
   ```

3. **DNS issues**:
   ```bash
   # Test DNS
   dig MX recipient-domain.com
   ```

### Issue: Emails marked as spam

**Symptoms**: Sent emails go to spam folder

**Solutions**:

1. **Set up SPF**:
   ```
   TXT record: v=spf1 mx ~all
   ```

2. **Set up DKIM**:
   ```bash
   # Install OpenDKIM
   sudo apt install opendkim opendkim-tools
   # See docs/SECURITY.md for setup
   ```

3. **Set up DMARC**:
   ```
   TXT record: v=DMARC1; p=none; rua=mailto:postmaster@example.com
   ```

4. **Configure reverse DNS**:
   - Contact hosting provider
   - Set PTR record: YOUR_IP → mail.example.com

5. **Test deliverability**:
   - Visit https://www.mail-tester.com/
   - Send email to the provided address
   - Review score and recommendations

## Email Receiving Issues

### Issue: Not receiving emails

**Symptoms**: External emails not arriving

**Diagnosis**:
```bash
# Check MX record
dig MX example.com

# Test SMTP reception
telnet mail.example.com 25

# Check Dovecot
sudo systemctl status dovecot

# View logs
sudo tail -f /var/log/mail.log
```

**Solutions**:

1. **MX record not set**:
   ```
   Add MX record: example.com → mail.example.com (Priority: 10)
   ```

2. **Firewall blocking**:
   ```bash
   sudo ufw allow 25/tcp
   ```

3. **User doesn't exist**:
   ```bash
   sudo ./scripts/manage-users.sh list-users
   sudo ./scripts/manage-users.sh add-user user@example.com password
   ```

### Issue: Emails received but not in inbox

**Symptoms**: Emails accepted but not visible in email client

**Diagnosis**:
```bash
# Check mail directory
sudo ls -la /var/mail/vhosts/example.com/user/new/

# Check Dovecot logs
sudo grep "user@example.com" /var/log/mail.log
```

**Solutions**:

1. **Wrong mail location**:
   ```bash
   # Check mail_location in Dovecot
   sudo doveconf -n | grep mail_location
   ```

2. **Permission issues**:
   ```bash
   sudo chown -R vmail:vmail /var/mail/vhosts/
   sudo chmod -R 770 /var/mail/vhosts/
   ```

3. **Quota exceeded**:
   ```bash
   # Check disk space
   df -h /var/mail
   ```

## Authentication Issues

### Issue: Cannot login to IMAP/POP3

**Symptoms**: "Authentication failed" in email client

**Diagnosis**:
```bash
# Test authentication
sudo doveadm auth test user@example.com password

# Check user exists
sudo mysql mailserver -e "SELECT * FROM virtual_users WHERE email='user@example.com';"

# View auth logs
sudo grep "auth" /var/log/mail.log
```

**Solutions**:

1. **Wrong password**:
   ```bash
   # Reset password
   sudo ./scripts/manage-users.sh change-password user@example.com newpassword
   ```

2. **User doesn't exist**:
   ```bash
   sudo ./scripts/manage-users.sh add-user user@example.com password
   ```

3. **Database connection issue**:
   ```bash
   # Test MySQL connection
   sudo mysql mailserver -e "SELECT * FROM virtual_users;"
   
   # Check Dovecot SQL config
   sudo cat /etc/dovecot/dovecot-sql.conf.ext
   ```

### Issue: Cannot send authenticated email

**Symptoms**: SMTP authentication fails

**Diagnosis**:
```bash
# Test SMTP auth
telnet mail.example.com 587
# After connection:
# EHLO mail.example.com
# Should see "250-AUTH PLAIN LOGIN"

# Check SASL
sudo postconf -n | grep sasl
```

**Solutions**:

1. **SASL not configured**:
   ```bash
   # Check Postfix main.cf
   sudo postconf -n | grep sasl_
   
   # Should include:
   # smtpd_sasl_auth_enable = yes
   # smtpd_sasl_type = dovecot
   # smtpd_sasl_path = private/auth
   ```

2. **Dovecot auth socket missing**:
   ```bash
   # Check socket exists
   ls -la /var/spool/postfix/private/auth
   
   # Restart Dovecot
   sudo systemctl restart dovecot
   ```

## SSL/TLS Issues

### Issue: SSL certificate error

**Symptoms**: "Certificate not trusted" or "Certificate expired"

**Diagnosis**:
```bash
# Check certificate
echo | openssl s_client -connect mail.example.com:993 2>/dev/null | openssl x509 -noout -dates

# Check certificate files
ls -la /etc/letsencrypt/live/mail.example.com/
```

**Solutions**:

1. **Certificate expired**:
   ```bash
   sudo certbot renew
   sudo systemctl restart postfix dovecot
   ```

2. **Wrong certificate**:
   ```bash
   # Regenerate certificate
   sudo certbot certonly --standalone -d mail.example.com --force-renewal
   ```

3. **Permission issues**:
   ```bash
   sudo chmod 0755 /etc/letsencrypt/{live,archive}
   sudo chmod 0644 /etc/letsencrypt/live/mail.example.com/*.pem
   ```

### Issue: TLS connection fails

**Symptoms**: "Cannot establish TLS connection"

**Diagnosis**:
```bash
# Test STARTTLS
openssl s_client -connect mail.example.com:587 -starttls smtp

# Test IMAPS
openssl s_client -connect mail.example.com:993
```

**Solutions**:

1. **Check TLS configuration**:
   ```bash
   sudo postconf -n | grep tls
   sudo doveconf -n | grep ssl
   ```

2. **Restart services**:
   ```bash
   sudo systemctl restart postfix dovecot
   ```

## Performance Issues

### Issue: Slow email delivery

**Symptoms**: Emails take long time to send/receive

**Diagnosis**:
```bash
# Check queue
sudo postqueue -p

# Check load
top

# Check disk I/O
iostat
```

**Solutions**:

1. **Increase queue workers**:
   ```bash
   # Edit /etc/postfix/main.cf
   default_process_limit = 100
   ```

2. **Check DNS**:
   ```bash
   # Test DNS resolution
   dig google.com
   ```

3. **Optimize database**:
   ```bash
   sudo mysql mailserver -e "OPTIMIZE TABLE virtual_users, virtual_domains, virtual_aliases;"
   ```

### Issue: High memory usage

**Symptoms**: Server running out of memory

**Solutions**:

1. **Reduce Postfix processes**:
   ```bash
   # Edit /etc/postfix/main.cf
   default_process_limit = 50
   ```

2. **Optimize MySQL**:
   ```bash
   # Edit /etc/mysql/my.cnf
   innodb_buffer_pool_size = 128M
   ```

## Database Issues

### Issue: Cannot connect to database

**Symptoms**: "Can't connect to MySQL" errors

**Diagnosis**:
```bash
# Check MySQL is running
sudo systemctl status mysql

# Test connection
sudo mysql -u mailuser -p mailserver
```

**Solutions**:

1. **MySQL not running**:
   ```bash
   sudo systemctl start mysql
   sudo systemctl enable mysql
   ```

2. **Wrong password**:
   ```bash
   # Reset password
   sudo mysql -e "ALTER USER 'mailuser'@'localhost' IDENTIFIED BY 'newpassword';"
   
   # Update config files
   sudo nano /etc/postfix/mysql-*.cf
   sudo nano /etc/dovecot/dovecot-sql.conf.ext
   ```

### Issue: User not found in database

**Symptoms**: User exists but cannot login

**Diagnosis**:
```bash
# Check user in database
sudo mysql mailserver -e "SELECT * FROM virtual_users WHERE email='user@example.com';"
```

**Solutions**:

1. **User missing**:
   ```bash
   sudo ./scripts/manage-users.sh add-user user@example.com password
   ```

2. **Domain missing**:
   ```bash
   sudo mysql mailserver -e "INSERT INTO virtual_domains (name) VALUES ('example.com');"
   ```

## General Diagnostic Commands

```bash
# Check all services
sudo systemctl status postfix dovecot mysql

# View all mail logs (last 100 lines)
sudo tail -100 /var/log/mail.log

# Watch logs in real-time
sudo tail -f /var/log/mail.log

# Check mail queue
sudo postqueue -p

# Test DNS
dig MX example.com
dig A mail.example.com

# Check open ports
sudo netstat -tlnp | grep -E '25|587|993|995'

# Check disk space
df -h

# Check memory
free -h
```

## Getting Help

If you can't resolve the issue:

1. **Collect information**:
   - Error messages
   - Log files (`/var/log/mail.log`)
   - Configuration (`postconf -n`, `doveconf -n`)
   - System info (`uname -a`, `df -h`, `free -h`)

2. **Search existing issues**:
   - GitHub Issues
   - Postfix documentation
   - Dovecot wiki

3. **Create an issue**:
   - Provide clear description
   - Include error messages
   - Attach relevant logs
   - Describe what you've tried

4. **Resources**:
   - [Postfix Documentation](http://www.postfix.org/documentation.html)
   - [Dovecot Wiki](https://doc.dovecot.org/)
   - [ZMAIL GitHub Issues](https://github.com/cruvzadmin/ZMAIL/issues)

---

**Tip**: Always check `/var/log/mail.log` first - it contains most error information!
