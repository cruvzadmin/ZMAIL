# Changelog

All notable changes to ZMAIL will be documented in this file.

## [1.0.0] - 2024-11-04

### Added

#### Core Components
- **Installation Script** (`scripts/install.sh`)
  - Automated installation of Postfix, Dovecot, MariaDB
  - System package updates and dependencies
  - Firewall (UFW) configuration
  - MySQL database creation with proper schema
  - Automatic backup of original configurations

- **Configuration Script** (`scripts/configure.sh`)
  - Post-installation configuration automation
  - Domain and hostname setup
  - vmail user creation
  - Configuration file deployment
  - MySQL password management
  - Directory structure creation with proper permissions

- **User Management Script** (`scripts/manage-users.sh`)
  - Add mail users with secure password hashing
  - Delete mail users
  - List all users
  - Change user passwords
  - Add email aliases
  - Delete email aliases
  - List all aliases

#### Postfix Configuration
- Main configuration (`config/postfix/main.cf`)
  - Virtual domain support
  - MySQL backend integration
  - Strong TLS/SSL settings (TLS 1.2+)
  - SASL authentication via Dovecot
  - Anti-spam measures (RBL, sender/recipient restrictions)
  - Message size limits
  - Queue management

- Master configuration (`config/postfix/master.cf`)
  - SMTP service (port 25)
  - Submission service (port 587)
  - SMTPS service (port 465)
  - All standard Postfix services

- MySQL integration files
  - Virtual mailbox domains lookup
  - Virtual mailbox maps
  - Virtual alias maps

#### Dovecot Configuration
- Main configuration (`config/dovecot/dovecot.conf`)
  - IMAP, POP3, and LMTP protocols
  - MySQL authentication backend

- Authentication (`config/dovecot/10-auth.conf`)
  - SQL-based passdb and userdb
  - Disabled plaintext auth (requires TLS)
  - PLAIN and LOGIN mechanisms

- Mail storage (`config/dovecot/10-mail.conf`)
  - Maildir format
  - Virtual mail hosting
  - Standard mailbox folders (Inbox, Sent, Drafts, Spam, Trash, Archive)

- Service configuration (`config/dovecot/10-master.conf`)
  - IMAP/IMAPS listeners
  - POP3/POP3S listeners
  - LMTP integration with Postfix
  - SASL authentication socket

- SSL/TLS (`config/dovecot/10-ssl.conf`)
  - Required SSL for all connections
  - TLS 1.2 minimum
  - Strong cipher suites
  - DH parameters support

- SQL integration (`config/dovecot/dovecot-sql.conf.ext`)
  - MySQL password queries
  - User iteration for management

#### Documentation
- **README.md**: Comprehensive main documentation
  - Feature overview
  - Architecture diagram
  - System requirements
  - Quick start guide
  - Configuration details
  - User management
  - Testing procedures
  - Security information
  - Monitoring and troubleshooting
  - Maintenance guidelines
  - Advanced configuration options

- **docs/INSTALLATION.md**: Detailed installation guide
  - Step-by-step installation process
  - DNS configuration requirements
  - Post-installation steps
  - Verification procedures
  - Troubleshooting installation issues

- **docs/QUICKSTART.md**: Quick start guide
  - 15-minute setup guide
  - Prerequisites checklist
  - Simplified instructions
  - Test procedures
  - Common issues and solutions

- **docs/SECURITY.md**: Security best practices
  - Initial security setup
  - SSL/TLS configuration
  - Firewall configuration
  - Fail2ban setup
  - SPF, DKIM, and DMARC
  - Authentication security
  - Regular maintenance tasks
  - Security monitoring
  - Incident response

- **docs/TROUBLESHOOTING.md**: Comprehensive troubleshooting
  - Installation issues
  - Service issues
  - Email sending/receiving problems
  - Authentication issues
  - SSL/TLS issues
  - Performance issues
  - Database issues
  - Diagnostic commands

- **CONTRIBUTING.md**: Contribution guidelines
  - How to report bugs
  - Feature suggestions
  - Pull request process
  - Coding standards
  - Testing guidelines
  - Security considerations

- **LICENSE**: MIT License

#### Security Features
- UFW firewall with minimal required ports
- Fail2ban integration for brute-force protection
- TLS 1.2+ only (no SSL, TLS 1.0, or TLS 1.1)
- Strong cipher suites
- SHA512-CRYPT password hashing
- Mandatory TLS for authentication
- RBL-based spam filtering
- Rate limiting
- Connection restrictions

#### Support Features
- Detailed logging
- MySQL database backend
- Multi-domain support
- Email alias support
- Let's Encrypt SSL integration
- Automatic certificate renewal hooks
- Maildir format for easy backup
- Queue management tools

### Technical Specifications

**Supported Platform**: Ubuntu 24.04 LTS

**Required Services**:
- Postfix (SMTP server)
- Dovecot (IMAP/POP3 server)
- MariaDB/MySQL (database)
- Certbot (SSL certificates)
- UFW (firewall)
- Fail2ban (intrusion prevention)

**Ports Used**:
- 25 (SMTP)
- 587 (Submission)
- 465 (SMTPS)
- 993 (IMAPS)
- 995 (POP3S)
- 80 (HTTP for Let's Encrypt)
- 443 (HTTPS)

**Directory Structure**:
- `/var/mail/vhosts/` - Mail storage
- `/etc/postfix/` - Postfix configuration
- `/etc/dovecot/` - Dovecot configuration
- `/etc/letsencrypt/` - SSL certificates

### Notes

This is the initial release of ZMAIL, providing a complete, production-ready email server solution for Ubuntu 24.04. The system is designed with security, reliability, and ease of use in mind.

All scripts have been tested for syntax correctness and follow bash best practices. Configuration files use secure defaults and are thoroughly documented.

### Known Limitations

- Designed specifically for Ubuntu 24.04 (may work on other Debian-based systems with modifications)
- Requires root/sudo access for installation
- Port 25 must be unblocked by hosting provider
- Requires a registered domain name with DNS access

### Future Considerations

Potential features for future releases:
- Web-based administration panel
- Integrated webmail (Roundcube/Rainloop)
- Automated DKIM setup
- Advanced spam filtering (SpamAssassin integration)
- Antivirus scanning (ClamAV integration)
- Backup automation
- Monitoring dashboard
- Docker container support
- Multiple server deployment
- Clustering support

---

**Release Date**: November 4, 2024  
**Version**: 1.0.0  
**Status**: Stable  
**License**: MIT
