# Libertas Software Documentation

## Operating System
**Distribution:** Debian  
**Kernel:** 6.1.0-17-amd64 #1 Debian 6.1.69-1  
**Architecture:** x86_64  
**Last Updated:** 2025-07-28

## Network Configuration

### Ethernet Driver
- **Driver:** igc (Intel Gigabit Controller)
- **Module:** /lib/modules/6.1.0-17-amd64/kernel/drivers/net/ethernet/intel/igc/igc.ko
- **Interface:** eth0 (PCI device 0000:0c:00.0)

### Network Management
- **Primary Service:** systemd-networkd (assumed)
- **Interface Status:** Experiencing intermittent failures

## Desktop Environment
- **DE/WM:** MATE (based on mate-multiload- process in stack trace)
- **Display Server:** X11 (likely)

## Monitoring
- **Heat Monitoring:** Required setup pending
- **Network Monitoring:** Built-in via mate-multiload applet

## Development Environment
- **Git Repositories:** Located in /mnt/nvme0n1p4/git/
- **Project Management:** ClodForest state management system

## System Services
- **SSH:** Tunnels to AWS VM 'vault3' (persistence needed)
- **Power Management:** Standard systemd power management

## Known Software Issues

### Kernel Modules
- **igc driver:** Known compatibility issues with PCIe power management
- **Audio drivers:** Motherboard audio non-functional despite device detection

### Configuration Needs
- PCIe ASPM configuration (kernel parameters or BIOS)
- SSH tunnel persistence across reboots
- Heat monitoring setup
- Audio subsystem troubleshooting

## Kernel Parameters (Recommended)
For ethernet stability:
```
GRUB_CMDLINE_LINUX_DEFAULT="quiet pcie_port_pm=off pcie_aspm.policy=performance"
```

## Log Locations
- **Kernel logs:** `/var/log/kern.log`
- **System logs:** `/var/log/syslog`
- **Journal:** `journalctl -u systemd-networkd`
- **Boot messages:** `dmesg`
