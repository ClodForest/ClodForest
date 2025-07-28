# Libertas Hardware Documentation

## System Overview
**Host:** Libertas  
**Type:** Desktop Server  
**Last Updated:** 2025-07-28

## Motherboard
- **Model:** ASUS ROG CROSSHAIR X870E HERO
- **BIOS:** Version 1203 (03/04/2025)

## Network Hardware

### Ethernet Controller
- **Chipset:** Intel Ethernet Controller (igc driver)
- **PCI ID:** 0000:0c:00.0
- **Interface Name:** eth0
- **Driver:** igc (Intel Gigabit Controller)
- **Status:** Experiencing PCIe link loss issues

**Known Issues:**
- Intermittent PCIe link loss causing complete network interface failure
- Requires system reboot to restore connectivity
- Error typically occurs during statistics polling (igc_update_stats)

## CPU
- **Architecture:** AMD x86_64
- **Temperature Monitoring:** Requires adequate heat monitoring setup

## Storage
- **Boot Drive:** nvme0n1p4 (contains git repositories and system state)

## Power Management
- **PCIe ASPM:** Likely causing ethernet interface issues
- **Recommendation:** Disable PCIe ASPM or set to performance mode

## Other Hardware Notes
- Motherboard audio devices detected but non-functional
- Multiple monitor setup supported
- System designed for 24/7 operation
