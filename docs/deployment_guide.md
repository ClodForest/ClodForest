# ClodForest Coordinator Deployment Guide

## Overview
The **ClodForest Coordinator** is a NodeJS/Express service that provides coordination services for distributed Claude instances. It offers time synchronization, repository access, and context coordination capabilities.

## Server Architecture
- **Service Name**: `clodforest-coordinator`
- **Runtime**: NodeJS + CoffeeScript
- **Default Port**: 8080 (configurable)
- **Repository Path**: `./state` (configurable)

## Prerequisites

### System Requirements
- [A compatible operating system](#tested-platforms) (Linux, FreeBSD, etc.)
- NodeJS 18+ installed
- [Git installed and configured](#git-setup)
- Basic development tools (for nvm compilation if needed)

### Node.js Installation

#### Option 1: Package Manager (Recommended for production)
```bash
# Amazon Linux / RHEL / CentOS
sudo yum install nodejs npm git

# Ubuntu / Debian
sudo apt update && sudo apt install nodejs npm git

# FreeBSD
sudo pkg install node18 npm git
```

#### Option 2: Node Version Manager (Recommended for development)
```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
source ~/.bashrc

# Install and use Node.js 18
nvm install 18
nvm use 18
nvm alias default 18

# Verify installation
node --version  # Should show v18.x.x
npm --version
```

### Git Setup
Ensure Git is properly configured:
```bash
git --version
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

For GitHub access, see [SSH key setup](#github-ssh-setup) below.

## Installation

### 1. Clone Repository
```bash
# Clone the ClodForest repository
git clone https://github.com/rdeforest/ClodForest.git
cd ClodForest

# Make install script executable
chmod +x bin/install.sh
```

### 2. Run Installation Script
```bash
# Run the automated installer
./bin/install.sh

# Or use the Cake task system
npm install -g coffeescript
cake setup
```

### 3. Test the Service
```bash
# Start in development mode
cake dev

# Test endpoints (in another terminal)
curl http://localhost:8080/api/health/
curl http://localhost:8080/api/time/test
curl http://localhost:8080/api/repo
```

### 4. Install as System Service
```bash
# Auto-detect platform and install service
cake install

# Or manually specify platform
cake install:systemd    # Linux with systemd
cake install:freebsd    # FreeBSD
cake install:sysv       # Devuan/older Linux
```

### 5. Start Production Service
```bash
# Using system service
sudo systemctl start clodforest      # systemd
sudo service clodforest start        # SysV
sudo service clodforest onestart     # FreeBSD

# Or run directly
cake start
```

## Configuration

### Default Configuration
ClodForest creates a `config.yaml` file during setup with sensible defaults:

```yaml
server:
  port: 8080
  vault_server: clodforest-vault
  log_level: info

repository:
  path: ./state

features:
  git_operations: false  # Disabled for security
  admin_auth: false      # Set to true for production
  context_updates: false # Not yet implemented

cors:
  origins:
    - https://claude.ai
    - https://*.claude.ai
    - http://localhost:3000
    - http://localhost:8080
```

### Environment Variables (Optional)
```bash
export PORT=8080
export VAULT_SERVER=clodforest-vault
export REPO_PATH=./state
export NODE_ENV=production
export LOG_LEVEL=info
```

### GitHub SSH Setup
For Git operations (when enabled):
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "clodforest@yourdomain.com" -f ~/.ssh/clodforest_github

# Add to SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/clodforest_github

# Configure SSH for GitHub
cat >> ~/.ssh/config << EOF
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/clodforest_github
    IdentitiesOnly yes
EOF

# Add public key to GitHub
cat ~/.ssh/clodforest_github.pub
# Copy output and add to GitHub Settings > SSH and GPG keys

# Test connection
ssh -T git@github.com
```

## API Endpoints

### Core Services

#### Health Check
```http
GET /api/health/
```
Returns service status, uptime, memory usage, and system information.

#### Time Service
```http
GET /api/time/{cachebuster}
```
Returns current timestamp in multiple formats. The cachebuster parameter ensures fresh responses.

### Repository Operations

#### List Repositories
```http
GET /api/repo
```
Returns all available repositories in the configured repository path.

#### Browse Repository Contents
```http
GET /api/repo/{repo}?path={directory}
```
Lists files and directories in the specified repository path.

#### Get File Contents
```http
GET /api/repo/{repo}/file/{filepath}
```
Returns the contents of a specific file in the repository.

#### Execute Git Commands (When Enabled)
```http
POST /api/repo/{repo}/git/{command}
Content-Type: application/json

{
  "args": ["--oneline", "--graph"]
}
```

**Note**: Git operations are disabled by default for security. Enable only after implementing proper authentication.

### Administrative Interface

#### Admin Dashboard
```http
GET /admin
```
Provides a web-based administrative interface for monitoring and management.

## Working with Claude's Restrictions

### URL Permission Limitations
Claude instances have restrictions on which URLs they can fetch:

1. **Cannot construct URLs dynamically** - All URLs must be explicitly provided
2. **Cannot fetch derived paths** - Even logical API extensions are blocked
3. **Cache-busting required** - Use wildcard routes like `/api/time/{anything}`

### Workarounds
- **Explicit URL provision**: Always provide complete URLs to Claude
- **Cache-busting paths**: Use `/api/time/random-string` format
- **API documentation**: Clearly document exact URLs Claude should use

### Example Claude-Compatible Usage
```
# Instead of constructing URLs, provide them explicitly:
Please fetch: https://yourhost.com/api/time/current-check
Please fetch: https://yourhost.com/api/repo/contexts/file/session-log.md
```

## Monitoring and Logs

### Service Management
```bash
# Check service status
sudo systemctl status clodforest        # systemd
sudo service clodforest status          # SysV/FreeBSD

# View logs
sudo journalctl -u clodforest -f        # systemd
tail -f /var/log/clodforest.log         # SysV/FreeBSD

# Restart service
sudo systemctl restart clodforest       # systemd
sudo service clodforest restart         # SysV/FreeBSD
```

### Development Monitoring
```bash
# Start with detailed logging
LOG_LEVEL=debug cake dev

# Check project status
cake status

# Run basic tests
cake test
```

## Security Considerations

### Current Security Features
- **Path traversal protection** - Prevents `../` attacks
- **Git command whitelist** - Only safe git operations allowed
- **CORS configuration** - Restricts cross-origin requests
- **Non-privileged execution** - Runs without system privileges

### Security Limitations & Future Work
- **No authentication** - Currently open access (development only)
- **Git operations disabled** - Requires authentication implementation
- **Admin interface** - No access control (development mode)

### Production Security Checklist
- [ ] Enable authentication (OAuth/JWT)
- [ ] Configure HTTPS with proper certificates
- [ ] Restrict network access via firewall
- [ ] Enable git operations only after auth implementation
- [ ] Regular security audits and updates

## Troubleshooting

### Common Issues

#### Service Won't Start
```bash
# Check CoffeeScript installation
coffee --version

# Verify entry point exists
ls -la src/coordinator/index.coffee

# Check for syntax errors
cake test

# Review logs
cake dev  # Will show errors directly
```

#### Repository Access Issues
```bash
# Check repository path
ls -la ./state

# Verify permissions
cake status

# Test API endpoints
curl http://localhost:8080/api/repo
```

#### Node.js Version Issues
```bash
# Check Node.js version
node --version  # Should be 18+

# Switch Node.js version (if using nvm)
nvm use 18
nvm alias default 18
```

### Platform-Specific Issues

#### Amazon Linux
```bash
# Install build tools if needed
sudo yum groupinstall "Development Tools"
sudo yum install python3
```

#### FreeBSD
```bash
# Ensure proper package versions
sudo pkg info node18 npm-node18
sudo pkg install python3 gmake
```

## Tested Platforms

| Platform | Version | Status | Notes |
|----------|---------|--------|-------|
| Amazon Linux | 2023 | ✅ Tested | Preferred AWS platform |
| Ubuntu | 20.04+ | ✅ Tested | systemd service |
| FreeBSD | 13.x | ✅ Tested | rc.d service |
| Devuan | 4.x | 🧪 Beta | SysV init service |
| CentOS/RHEL | 8+ | 🧪 Beta | systemd service |
| macOS | Latest | ⚠️ Manual | No service auto-install |

## Next Steps

### Immediate Priorities
1. **Authentication System** - Implement OAuth/JWT for production use
2. **Git Operations Security** - Enable git commands with proper auth
3. **HTTPS Configuration** - SSL/TLS setup documentation
4. **Monitoring Integration** - CloudWatch/Grafana setup

### Future Enhancements
1. **Multi-instance Coordination** - Distributed coordinator support
2. **Database Integration** - Persistent storage for context data
3. **CI/CD Pipeline** - Automated testing and deployment
4. **Rate Limiting** - Per-instance request throttling
5. **Advanced Security** - WAF integration, audit logging

## Support

For issues and questions:
- **GitHub Issues**: https://github.com/rdeforest/ClodForest/issues
- **Documentation**: https://clodforest.thatsnice.org/docs
- **Contact**: robert@defore.st

---

*Last updated: November 2024*
