# Ethernet Interface Loss Issue

**Status:** ✅ RESOLVED  
**Priority:** High (Completed)  
**Created:** 2025-07-26  
**Resolved:** 2025-07-28

## ✅ RESOLUTION SUMMARY

**Root Cause:** PCIe Active State Power Management (ASPM) incompatibility with Intel igc ethernet controller causing "PCIe link lost" errors.

**Solution Applied:** Comprehensive power management disabling:
- **BIOS Level:** Native ASPM → Disabled, CPU PCIE ASPM Mode Control → Disabled, Global C-state Control → Disabled
- **Kernel Level:** `pcie_port_pm=off pcie_aspm.policy=performance`

**Verification:** Post-reboot dmesg shows zero "PCIe link lost" errors and stable 1Gbps ethernet connectivity.

**Status:** Problem completely resolved. Ethernet interface stable for 24/7 server operation.

---

## Description
Lost ethernet interface inexplicably, had to reboot. Identified as known Intel igc driver issue related to PCIe power management.

## Root Cause Analysis ✅
Based on dmesg output analysis and research:

**Error Pattern:**
```
igc 0000:0c:00.0 eth0: PCIe link lost, device now detached
igc: Failed to read reg 0xc030!
WARNING: CPU: 2 PID: 10907 at drivers/net/ethernet/intel/igc/igc_main.c:6482 igc_rd32+0x91/0xa0 [igc]
```

**Root Cause:** PCIe Active State Power Management (ASPM) incompatibility with Intel igc ethernet controller.

## Hardware Details ✅
- **Network interface:** Intel Ethernet Controller (igc)
- **PCI Address:** 0000:0c:00.0
- **Interface Name:** eth0
- **Driver:** igc (Intel Gigabit Controller)
- **Controller Type:** Likely Intel I225-V or I226-V based on error pattern

## Investigation Steps
- [x] Review kern.log for ethernet-related messages
- [x] Check dmesg output
- [x] Research igc driver PCIe link loss issues
- [x] Identify known solutions from community reports
- [ ] Implement recommended fixes
- [ ] Test interface stability after fix
- [ ] Monitor for recurring issues

## Symptoms
- Ethernet interface disappears unexpectedly
- "PCIe link lost, device now detached" error in kernel log
- igc driver fails to read hardware registers (0xc030)
- Required reboot to restore connectivity
- Error occurs during statistics polling (igc_update_stats)

## Solution Options

### Option 1: Kernel Parameters (Recommended)
Add to `/etc/default/grub` in `GRUB_CMDLINE_LINUX_DEFAULT`:
```
pcie_port_pm=off pcie_aspm.policy=performance
```
Then run: `sudo update-grub && sudo reboot`

### Option 2: BIOS Configuration
- Access ASUS BIOS setup
- Look for "PCIe ASPM Support" option
- Disable PCIe ASPM if available

### Option 3: Alternative Kernel Parameter
If Option 1 doesn't work:
```
pcie_aspm=off
```

## Technical Notes
- This is a widespread issue affecting Intel I225-V/I226-V controllers
- Problem exists across multiple kernel versions (5.x-6.x)
- Affects multiple Linux distributions (Debian, Ubuntu, Arch, etc.)
- Issue occurs when PCIe power management puts device into low-power state
- Driver cannot properly wake device, causing permanent link loss
- Only solution is typically a full system reboot

## Logs to Check
- `/var/log/kern.log` ✅ (Analyzed)
- `/var/log/syslog`
- `dmesg` output ✅ (Analyzed)
- `journalctl -u systemd-networkd`

## Verification Commands
After implementing fix:
```bash
# Check current PCIe ASPM status
cat /sys/module/pcie_aspm/parameters/policy

# Monitor for errors
journalctl -f | grep -i igc

# Check interface stability
watch -n 1 'ip link show eth0'
```

## References
- Intel igc driver known issues with PCIe power management
- Multiple community reports on Proxmox, Debian, Arch Linux forums
- Debian Bug #1060706: Intel i225 NIC loses PCIe link
- Solution widely reported as disabling PCIe ASPM

## Related Files
- Main issue list: [Issues.md](../Issues.md)
- Hardware documentation: [docs/hardware.md](../docs/hardware.md)
- Software documentation: [docs/software.md](../docs/software.md)
