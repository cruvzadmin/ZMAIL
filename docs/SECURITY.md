# ZMAIL Security Guide

This guide covers security best practices and hardening steps for your ZMAIL email server.

## Table of Contents

1. [Initial Security Setup](#initial-security-setup)
2. [SSL/TLS Configuration](#ssltls-configuration)
3. [Firewall Configuration](#firewall-configuration)
4. [Fail2ban Setup](#fail2ban-setup)
5. [Authentication Security](#authentication-security)
6. [SPF, DKIM, and DMARC](#spf-dkim-and-dmarc)
7. [Regular Maintenance](#regular-maintenance)
8. [Security Monitoring](#security-monitoring)

## Initial Security Setup

### Secure SSH Access

1. **Change SSH Port** (optional but recommended):

```bash
sudo nano /etc/ssh/sshd_config
```

Change:
```
Port 22
```
to:
```
Port 2222
```

2. **Disable Root Login**:

```bash
sudo nano /etc/ssh/sshd_config
```

Set:
```
PermitRootLogin no
PasswordAuthentication no  # Use SSH keys only
```

3. **Restart SSH**:

```bash
sudo systemctl restart sshd
```

### Keep System Updated

Set up automatic security updates:

```bash
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

Edit `/etc/apt/apt.conf.d/50unattended-upgrades`:

```
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
```

## SSL/TLS Configuration

### Strong SSL Configuration

ZMAIL is pre-configured with strong SSL settings, but verify:

#### Postfix TLS Settings

Check `/etc/postfix/main.cf`:

```
# Minimum TLS version
smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtp_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1

# Strong ciphers only
smtpd_tls_ciphers = high
smtpd_tls_mandatory_ciphers = high
smtp_tls_ciphers = high

# Exclude weak ciphers
smtpd_tls_exclude_ciphers = aNULL, MD5, DES, 3DES, DES-CBC3-SHA, RC4-SHA, AES256-SHA, AES128-SHA
```

#### Dovecot TLS Settings

Check `/etc/dovecot/conf.d/10-ssl.conf`:

```
ssl = required
ssl_min_protocol = TLSv1.2
ssl_cipher_list = ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:...
ssl_prefer_server_ciphers = yes
```

### Test SSL Configuration

```bash
# Test SMTP TLS
openssl s_client -connect mail.example.com:587 -starttls smtp

# Test IMAP TLS
openssl s_client -connect mail.example.com:993

# Check certificate expiry
echo | openssl s_client -connect mail.example.com:993 2>/dev/null | openssl x509 -noout -dates
```

### SSL Best Practices

1. **Use Let's Encrypt certificates** (free and auto-renewed)
2. **Monitor certificate expiration** (30 days before expiry)
3. **Use HSTS headers** for webmail
4. **Generate strong DH parameters**:

```bash
sudo openssl dhparam -out /etc/dovecot/dh.pem 4096
```

## Firewall Configuration

### UFW (Uncomplicated Firewall)

ZMAIL installation configures UFW automatically. Verify:

```bash
sudo ufw status verbose
```

Expected output:
```
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
25/tcp                     ALLOW       Anywhere
587/tcp                    ALLOW       Anywhere
465/tcp                    ALLOW       Anywhere
993/tcp                    ALLOW       Anywhere
995/tcp                    ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
443/tcp                    ALLOW       Anywhere
```

### Additional Firewall Hardening

1. **Limit SSH connections**:

```bash
sudo ufw limit 22/tcp
```

2. **Allow specific IPs only** (if applicable):

```bash
sudo ufw delete allow 22
sudo ufw allow from YOUR_IP to any port 22
```

3. **Log firewall events**:

```bash
sudo ufw logging on
```

## Fail2ban Setup

Fail2ban protects against brute-force attacks.

### Installation

Already installed by ZMAIL installer, but verify:

```bash
sudo systemctl status fail2ban
```

### Configuration

Create `/etc/fail2ban/jail.local`:

```bash
sudo nano /etc/fail2ban/jail.local
```

Add:

```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = admin@example.com
sendername = Fail2Ban
action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[postfix]
enabled = true
port = smtp,465,587
filter = postfix
logpath = /var/log/mail.log
maxretry = 5

[dovecot]
enabled = true
port = pop3,pop3s,imap,imaps
filter = dovecot
logpath = /var/log/mail.log
maxretry = 5

[postfix-sasl]
enabled = true
port = smtp,465,587
filter = postfix-sasl
logpath = /var/log/mail.log
maxretry = 3
```

### Create Filters

Postfix SASL filter (`/etc/fail2ban/filter.d/postfix-sasl.conf`):

```ini
[Definition]
failregex = ^%(__prefix_line)swarning: [-._\w]+\[<HOST>\]: SASL (?:LOGIN|PLAIN|(?:CRAM|DIGEST)-MD5) authentication failed(?:: [ A-Za-z0-9+/]*={0,2})?\s*$
ignoreregex =
```

### Restart Fail2ban

```bash
sudo systemctl restart fail2ban
```

### Monitor Fail2ban

```bash
# Check status
sudo fail2ban-client status

# Check specific jail
sudo fail2ban-client status postfix

# Unban an IP
sudo fail2ban-client set postfix unbanip IP_ADDRESS
```

## Authentication Security

### Strong Password Policy

1. **Enforce strong passwords** when creating users
2. **Minimum requirements**:
   - At least 12 characters
   - Mix of uppercase, lowercase, numbers, symbols
   - No dictionary words

### Password Hashing

ZMAIL uses SHA512-CRYPT for password hashing. Verify in user creation script:

```bash
doveadm pw -s SHA512-CRYPT -p "password"
```

### Disable Plain-text Auth

Already configured in Dovecot, but verify:

```bash
sudo doveconf -n | grep disable_plaintext_auth
```

Should return:
```
disable_plaintext_auth = yes
```

### Rate Limiting

Postfix configuration in `/etc/postfix/main.cf`:

```
# Connection limits
smtpd_client_connection_count_limit = 10
smtpd_client_connection_rate_limit = 30
smtpd_client_message_rate_limit = 100
```

## SPF, DKIM, and DMARC

### SPF (Sender Policy Framework)

Already configured in DNS. Verify:

```bash
dig TXT example.com | grep spf
```

Should return:
```
example.com. 3600 IN TXT "v=spf1 mx ~all"
```

### DKIM (DomainKeys Identified Mail)

1. **Install OpenDKIM**:

```bash
sudo apt install opendkim opendkim-tools
```

2. **Configure OpenDKIM**:

Edit `/etc/opendkim.conf`:

```
Syslog yes
UMask 002
Mode sv
Canonicalization relaxed/simple
Domain example.com
Selector default
KeyFile /etc/opendkim/keys/example.com/default.private
Socket inet:8891@localhost
```

3. **Generate Keys**:

```bash
sudo mkdir -p /etc/opendkim/keys/example.com
sudo opendkim-genkey -b 2048 -d example.com -D /etc/opendkim/keys/example.com -s default -v
sudo chown -R opendkim:opendkim /etc/opendkim
sudo chmod 600 /etc/opendkim/keys/example.com/default.private
```

4. **Get Public Key**:

```bash
sudo cat /etc/opendkim/keys/example.com/default.txt
```

5. **Add DNS Record**:

```
Type: TXT
Name: default._domainkey.example.com
Value: (the public key from above)
```

6. **Configure Postfix**:

Edit `/etc/postfix/main.cf`:

```
milter_protocol = 6
milter_default_action = accept
smtpd_milters = inet:localhost:8891
non_smtpd_milters = inet:localhost:8891
```

7. **Restart Services**:

```bash
sudo systemctl restart opendkim
sudo systemctl restart postfix
```

### DMARC

Add DNS TXT record:

```
Type: TXT
Name: _dmarc.example.com
Value: v=DMARC1; p=quarantine; rua=mailto:dmarc-reports@example.com; ruf=mailto:dmarc-forensics@example.com; fo=1
```

Policy options:
- `p=none` - Monitor only
- `p=quarantine` - Mark as spam
- `p=reject` - Reject emails

## Regular Maintenance

### Daily Tasks

1. **Check logs for errors**:

```bash
sudo tail -100 /var/log/mail.log | grep -i error
```

2. **Check mail queue**:

```bash
sudo postqueue -p
```

3. **Monitor disk usage**:

```bash
sudo df -h /var/mail
```

### Weekly Tasks

1. **Review Fail2ban logs**:

```bash
sudo fail2ban-client status postfix
sudo fail2ban-client status dovecot
```

2. **Check for updates**:

```bash
sudo apt update
sudo apt list --upgradable
```

3. **Backup database**:

```bash
sudo mysqldump mailserver > /backup/mailserver-$(date +%Y%m%d).sql
```

### Monthly Tasks

1. **Test SSL certificate renewal**:

```bash
sudo certbot renew --dry-run
```

2. **Review user accounts**:

```bash
sudo ./scripts/manage-users.sh list-users
```

3. **Clean old logs**:

```bash
sudo journalctl --vacuum-time=30d
```

## Security Monitoring

### Log Monitoring

Set up logwatch:

```bash
sudo apt install logwatch
sudo logwatch --detail High --mailto admin@example.com --range today
```

### Real-time Monitoring

Monitor in real-time:

```bash
# Watch authentication attempts
sudo tail -f /var/log/mail.log | grep 'auth'

# Watch failed logins
sudo tail -f /var/log/mail.log | grep 'failed'

# Watch Fail2ban bans
sudo tail -f /var/log/fail2ban.log
```

### Security Auditing

1. **Check open ports**:

```bash
sudo netstat -tlnp
```

2. **Check running processes**:

```bash
sudo ps aux | grep -E 'postfix|dovecot'
```

3. **Check for suspicious files**:

```bash
sudo find /var/mail -type f -mtime -1
```

### Email Testing Services

Test your email security:

1. **MX Toolbox**: https://mxtoolbox.com/
2. **Mail Tester**: https://www.mail-tester.com/
3. **DKIM Validator**: https://dkimvalidator.com/

## Security Checklist

- [ ] SSH secured with key-based authentication
- [ ] Firewall (UFW) enabled and configured
- [ ] Fail2ban installed and monitoring
- [ ] SSL/TLS certificates valid and auto-renewing
- [ ] Strong password policy enforced
- [ ] SPF record configured
- [ ] DKIM signing enabled
- [ ] DMARC policy published
- [ ] Regular backups scheduled
- [ ] Log monitoring in place
- [ ] System updates automated
- [ ] Reverse DNS (PTR) configured
- [ ] Rate limiting configured
- [ ] Port 25 egress allowed (not blocked by ISP)

## Incident Response

If you detect suspicious activity:

1. **Immediately check logs**:
   ```bash
   sudo tail -1000 /var/log/mail.log | grep -i 'IP_ADDRESS'
   ```

2. **Ban IP if needed**:
   ```bash
   sudo fail2ban-client set postfix banip IP_ADDRESS
   ```

3. **Check for spam**:
   ```bash
   sudo postqueue -p | grep IP_ADDRESS
   ```

4. **Flush queue if compromised**:
   ```bash
   sudo postsuper -d ALL deferred
   ```

5. **Change passwords**:
   ```bash
   sudo ./scripts/manage-users.sh change-password user@example.com new_password
   ```

## Additional Resources

- [Postfix Security](http://www.postfix.org/SASL_README.html)
- [Dovecot Security](https://doc.dovecot.org/configuration_manual/howto/ssl_ca/)
- [OWASP Email Security](https://cheatsheetseries.owasp.org/cheatsheets/Email_Security_Cheat_Sheet.html)

---

**Remember**: Security is an ongoing process. Regularly review and update your security measures.
