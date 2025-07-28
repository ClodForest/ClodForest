# SSH Tunnel Persistence Issue

**Status:** Open  
**Priority:** Medium  
**Created:** 2025-07-26

## Description
Need to make SSH tunnels to AWS VM 'vault3' persist across reboots. Currently need to manually establish tunnels after each reboot.

## Current Tunnel Commands
- `ssh -R *:8086:localhost:11434 vault3`
- `ssh -R *:8022:localhost:22 vault3`

## Investigation Steps
- [ ] Research systemd service approach for persistent tunnels
- [ ] Consider using autossh for automatic reconnection
- [ ] Set up SSH key authentication (if not already configured)
- [ ] Create systemd service files for each tunnel
- [ ] Test tunnel persistence across reboots
- [ ] Configure tunnel monitoring and auto-restart

## Tunnel Details
- **Tunnel 1:** vault3:8086 → localhost:11434 (likely Ollama service)
- **Tunnel 2:** vault3:8022 → localhost:22 (SSH access to libertas)
- **Direction:** Reverse tunnels (-R flag)
- **Target:** AWS VM 'vault3'

## Implementation Options
1. **systemd services** - Most robust for auto-start/restart
2. **autossh** - Automatic reconnection on failure
3. **cron @reboot** - Simple but less reliable
4. **SSH config + systemd** - Combination approach

## Requirements
- Tunnels must auto-establish on boot
- Automatic reconnection on network issues
- Proper logging for troubleshooting
- Clean shutdown handling

## Notes
- Port 11434 suggests Ollama LLM service
- Port 8022 provides SSH backdoor access via vault3
- Need to ensure SSH keys are properly configured
- Consider security implications of persistent tunnels

## Related Files
- Main issue list: [Issues.md](../Issues.md)
- SSH config: `/home/robert/.ssh/config`
- Systemd services: `/etc/systemd/system/` (when created)
