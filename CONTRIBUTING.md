# Contributing to ZMAIL

Thank you for your interest in contributing to ZMAIL! This document provides guidelines for contributing to the project.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue on GitHub with:

1. **Description**: Clear description of the bug
2. **Steps to Reproduce**: Detailed steps to reproduce the issue
3. **Expected Behavior**: What should happen
4. **Actual Behavior**: What actually happens
5. **Environment**:
   - Ubuntu version
   - ZMAIL version
   - Postfix version
   - Dovecot version
6. **Logs**: Relevant log entries from `/var/log/mail.log`

### Suggesting Features

Feature suggestions are welcome! Please create an issue with:

1. **Use Case**: Why is this feature needed?
2. **Proposed Solution**: How should it work?
3. **Alternatives**: Other approaches you've considered
4. **Additional Context**: Screenshots, examples, etc.

### Pull Requests

1. **Fork the Repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/ZMAIL.git
   cd ZMAIL
   ```

2. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Your Changes**
   - Follow the coding style used in the project
   - Test your changes thoroughly
   - Update documentation if needed

4. **Test Your Changes**
   - Test on a clean Ubuntu 24.04 installation
   - Verify all scripts work correctly
   - Check for syntax errors: `bash -n script.sh`

5. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "Add feature: your feature description"
   ```

6. **Push to Your Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create Pull Request**
   - Provide clear description of changes
   - Reference any related issues
   - Include test results

## Coding Standards

### Bash Scripts

- Use `#!/bin/bash` shebang
- Set `set -e` for error handling
- Use meaningful variable names (UPPERCASE for globals)
- Add comments for complex logic
- Include error messages with colors
- Validate user inputs
- Check for required commands/packages

Example:
```bash
#!/bin/bash
set -e

# Color codes
GREEN='\033[0;32m'
NC='\033[0m'

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[ERROR]${NC} This script must be run as root"
   exit 1
fi
```

### Configuration Files

- Use clear, descriptive comments
- Include security best practices
- Use sensible defaults
- Document required changes
- Use example.com for examples

### Documentation

- Use Markdown format
- Include code examples
- Add table of contents for long documents
- Use clear headings and structure
- Include troubleshooting sections
- Keep language clear and concise

## Project Structure

```
ZMAIL/
├── config/              # Configuration templates
│   ├── postfix/        # Postfix configs
│   └── dovecot/        # Dovecot configs
├── scripts/            # Installation and management scripts
│   ├── install.sh      # Main installation script
│   ├── configure.sh    # Configuration script
│   └── manage-users.sh # User management script
├── docs/               # Documentation
│   ├── INSTALLATION.md # Detailed installation guide
│   ├── SECURITY.md     # Security best practices
│   └── QUICKSTART.md   # Quick start guide
├── README.md           # Main documentation
└── .gitignore         # Git ignore file
```

## Testing Guidelines

### Before Submitting PR

1. **Syntax Check**
   ```bash
   bash -n scripts/*.sh
   ```

2. **Test on Clean System**
   - Use fresh Ubuntu 24.04 VM or container
   - Run installation from scratch
   - Verify all features work

3. **Check Logs**
   - No errors in `/var/log/mail.log`
   - Services start correctly
   - Configuration is valid

4. **Test Email Flow**
   - Send email via SMTP
   - Receive email via IMAP
   - Test authentication
   - Verify SSL/TLS

### Test Checklist

- [ ] Installation completes without errors
- [ ] Configuration applies correctly
- [ ] Postfix starts and accepts mail
- [ ] Dovecot starts and serves mailboxes
- [ ] SSL certificates work
- [ ] User management works
- [ ] Firewall rules apply
- [ ] Documentation is updated
- [ ] No syntax errors in scripts

## Security Considerations

When contributing, keep security in mind:

1. **Never commit**:
   - Passwords or secrets
   - Private keys
   - Real domain names
   - IP addresses

2. **Always**:
   - Use placeholder values (example.com)
   - Hash passwords properly
   - Use secure defaults
   - Validate all inputs
   - Set proper file permissions

3. **Security Review**:
   - Check for injection vulnerabilities
   - Verify file permissions
   - Test with malicious inputs
   - Review SSL/TLS settings

## Code Review Process

1. **Automated Checks**: Scripts are checked for syntax
2. **Manual Review**: Maintainers review code and test
3. **Testing**: Changes are tested on clean system
4. **Feedback**: Reviewers provide feedback
5. **Approval**: Once approved, PR is merged

## Getting Help

- **Documentation**: Check README.md and docs/
- **Issues**: Search existing issues
- **Discussions**: Use GitHub Discussions
- **Email**: Contact maintainers

## License

By contributing to ZMAIL, you agree that your contributions will be licensed under the same license as the project.

## Recognition

Contributors will be recognized in:
- GitHub contributors list
- Release notes
- Project documentation

Thank you for contributing to ZMAIL! 🎉
