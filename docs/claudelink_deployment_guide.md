# ClaudeLink Coordinator Deployment Guide

## Overview
The **ClaudeLink Coordinator** is a NodeJS/Express service that provides the active portion of the ClaudeLink protocol. It runs under the `ec2-user` account and provides time services, repository access, and context coordination for distributed Claude instances.

## Server Architecture
- **Service Name**: `claudelink-coordinator`  
- **FreeBSD Repository Server**: `claudelink-vault`
- **Runtime**: NodeJS + Express
- **Port**: 8080 (non-privileged)
- **User**: ec2-user

## Prerequisites

### System Requirements
- Amazon Linux 2 or compatible
- NodeJS 18+ installed
- Git installed and configured
- Network access to FreeBSD repository server (`claudelink-vault`)
- Directory `/var/repositories` with appropriate permissions

### Setup Repository Access
```bash
# Create repository directory
sudo mkdir -p /var/repositories
sudo chown ec2-user:ec2-user /var/repositories
sudo chmod 755 /var/repositories

# Test FreeBSD server connectivity
ping claudelink-vault
```

## Installation

### 1. Clone and Setup Application
```bash
# Switch to ec2-user
sudo su - ec2-user

# Create application directory
mkdir -p ~/claudelink-coordinator
cd ~/claudelink-coordinator

# Copy service files (server.js, package.json)
# ... copy the artifacts created above ...

# Install dependencies
npm install
```

### 2. Test the Service
```bash
# Run in development mode
npm run dev

# Test endpoints
curl http://localhost:8080/api/health
curl http://localhost:8080/api/time
curl http://localhost:8080/api/repository
```

### 3. Install as System Service
```bash
# Copy systemd service file
sudo cp claudelink-coordinator.service /etc/systemd/system/

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable claudelink-coordinator

# Start the service
sudo systemctl start claudelink-coordinator

# Check status
sudo systemctl status claudelink-coordinator
```

## API Endpoints

### Core Services

#### Health Check
```http
GET /api/health
```
Returns service status, uptime, and version information.

#### Time Service
```http
GET /api/time
```
Returns current timestamp in multiple formats for instance synchronization.

### Repository Operations

#### List Repositories
```http
GET /api/repository
```
Returns all repositories available on the `claudelink-vault` server.

#### Browse Repository Contents
```http
GET /api/repository/{repo}?path={directory}
```
Lists files and directories in the specified repository path.

#### Get File Contents
```http
GET /api/repository/{repo}/file/{filepath}
```
Returns the contents of a specific file in the repository.

#### Execute Git Commands
```http
POST /api/repository/{repo}/git/{command}
Content-Type: application/json

{
  "args": ["--oneline", "--graph"]
}
```

Allowed git commands:
- `status` - Repository status
- `log` - Commit history  
- `diff` - Show changes
- `branch` - List/manage branches
- `pull` - Pull updates
- `push` - Push changes
- `checkout` - Switch branches/files

### Context Management

#### Update Context
```http
POST /api/context/update
Content-Type: application/json
X-ClaudeLink-Instance: claudelink-dev-001

{
  "requestor": "claudelink-dev-001",
  "requests": [
    {
      "type": "context_update",
      "context": "ClaudeLink/development/status", 
      "target_path": "/projects/new-context.yaml",
      "changes": {
        "format": "base64_unified_diff",
        "data": "..."
      }
    }
  ]
}
```

### Instance Coordination

#### List Active Instances
```http
GET /api/instances
```
Returns list of active Claude instances in the network.

## Configuration

### Environment Variables
```bash
# Required
export PORT=8080
export FREEBSD_SERVER=claudelink-vault
export REPO_PATH=/var/repositories

# Optional
export NODE_ENV=production
export LOG_LEVEL=info
```

### Security Configuration
- Service runs as non-privileged `ec2-user`
- Repository access restricted to `/var/repositories`
- Git commands whitelist enforced
- Path traversal protection enabled
- CORS configured for Claude instance origins

## Monitoring and Logs

### Service Management
```bash
# Check service status
sudo systemctl status claudelink-coordinator

# View logs
sudo journalctl -u claudelink-coordinator -f

# Restart service
sudo systemctl restart claudelink-coordinator

# Stop service  
sudo systemctl stop claudelink-coordinator
```

### Log Monitoring
```bash
# Follow service logs
npm run logs

# Check for errors
sudo journalctl -u claudelink-coordinator --since "1 hour ago" | grep ERROR
```

## Integration with ClaudeLink Protocol

### Context Updates
The service processes YAML-based context updates with base64-encoded unified diffs, allowing Claude instances to share and synchronize their contexts.

### Repository Synchronization
Git operations enable Claude instances to collaborate on shared codebases and maintain version control across the distributed network.

### Time Synchronization
Centralized time service ensures consistent timestamps across all Claude instances for proper coordination.

## Security Considerations

1. **Access Control**: Future versions will implement token-based authentication
2. **Network Security**: Configure firewall rules to restrict access to trusted Claude instances
3. **Repository Security**: Ensure proper permissions on `/var/repositories`
4. **Process Isolation**: Service runs with restricted system access via systemd

## Troubleshooting

### Common Issues

#### Service Won't Start
```bash
# Check service status
sudo systemctl status claudelink-coordinator

# Check logs for errors
sudo journalctl -u claudelink-coordinator --since "5 minutes ago"

# Verify Node.js and dependencies
node --version
npm list
```

#### Repository Access Issues
```bash
# Check repository permissions
ls -la /var/repositories

# Test git connectivity to FreeBSD server
git clone user@claudelink-vault:/path/to/test-repo.git /tmp/test

# Verify SSH keys if using SSH git access
ssh-add -l
```

#### Network Connectivity
```bash
# Test service endpoint
curl http://localhost:8080/api/health

# Check port binding
netstat -tlnp | grep 8080

# Test external access (if applicable)
curl http://ec2-34-216-125-155.us-west-2.compute.amazonaws.com:8080/api/health
```

## Next Steps

1. **Token Authentication**: Implement secure token-based authentication
2. **SSL/TLS**: Configure HTTPS with CloudFront integration
3. **Rate Limiting**: Add per-instance request rate limiting
4. **Monitoring**: Integrate with AWS CloudWatch for metrics
5. **Clustering**: Support for multiple coordinator instances
6. **Database Integration**: Add persistent storage for context and instance data

## Support

For issues and questions:
- GitHub Issues: https://github.com/rdeforest/claudelink-coordinator/issues
- Documentation: https://claudelink.thatsnice.org/docs
- Contact: rdeforest@thatsnice.org