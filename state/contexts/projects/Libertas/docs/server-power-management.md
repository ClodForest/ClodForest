# Server Power Management Configuration

**Purpose:** Ensure rock-solid stability for always-up server operation  
**Philosophy:** Disable all power management except display power saving  
**Created:** 2025-07-28

## Kernel Parameters for Server Stability

Add to `/etc/default/grub` in `GRUB_CMDLINE_LINUX_DEFAULT`:

```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet pcie_port_pm=off pcie_aspm.policy=performance processor.max_cstate=1 intel_idle.max_cstate=0 usbcore.autosuspend=-1"
```

### Parameter Breakdown:
- `pcie_port_pm=off` - Disable PCIe port power management
- `pcie_aspm.policy=performance` - Set PCIe ASPM to performance mode  
- `processor.max_cstate=1` - Limit CPU deep sleep states (AMD/Intel)
- `intel_idle.max_cstate=0` - Disable Intel CPU idle driver deep states
- `usbcore.autosuspend=-1` - Disable USB autosuspend globally

## Additional System Configuration

### 1. Disable System Suspend/Hibernate
```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

### 2. Network Interface Power Management
```bash
# Check current power management status
sudo ethtool eth0 | grep -i wake

# Disable power management on ethernet (add to startup script)
echo 'ethtool -s eth0 wol d' >> /etc/rc.local
```

### 3. SATA/NVMe Power Management
Add to kernel parameters if needed:
```bash
ahci.mobile_lpm_policy=0 nvme_core.default_ps_max_latency_us=0
```

### 4. Runtime Power Management
Create `/etc/udev/rules.d/90-disable-power-management.rules`:
```bash
# Disable runtime power management for all PCI devices
SUBSYSTEM=="pci", ATTR{power/control}="on"

# Disable USB autosuspend for all devices
SUBSYSTEM=="usb", ATTR{power/autosuspend}="-1"
SUBSYSTEM=="usb", ATTR{power/control}="on"
```

### 5. CPU Governor (Optional)
For maximum performance consistency:
```bash
# Set CPU governor to performance
echo 'performance' | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Make permanent in /etc/rc.local or systemd service
```

## BIOS/UEFI Settings (ASUS ROG CROSSHAIR X870E HERO)

### Disable in BIOS:
- **PCIe ASPM Support** → Disabled
- **USB Power Management** → Disabled  
- **SATA Power Management** → Disabled
- **CPU C-States** → Disabled (if maximum stability preferred)
- **Platform Power Management** → Disabled
- **ErP Ready** → Disabled
- **Deep Sleep** → Disabled

### Keep Enabled:
- **Monitor Power Management** (displays can sleep)
- **Fan Control** (thermal management still needed)

## Verification Commands

```bash
# Check PCIe ASPM status
cat /sys/module/pcie_aspm/parameters/policy

# Check CPU C-states
grep . /sys/devices/system/cpu/cpu*/cpuidle/state*/disable

# Check USB autosuspend status
for device in /sys/bus/usb/devices/*/power/autosuspend; do
    echo "$device: $(cat $device 2>/dev/null || echo 'N/A')"
done

# Check systemd power management targets
systemctl status sleep.target suspend.target hibernate.target
```

## Implementation Steps

1. **Update GRUB configuration**
2. **Reboot and test ethernet stability**
3. **Disable systemd power management targets**
4. **Create udev rules for runtime PM**
5. **Configure BIOS settings**
6. **Monitor system for 48-72 hours**

## Monitoring

Create a simple monitoring script to ensure nothing goes offline:
```bash
#!/bin/bash
# /usr/local/bin/server-health-check.sh
while true; do
    echo "$(date): Network: $(ip link show eth0 | grep 'state UP' && echo 'OK' || echo 'FAILED')"
    echo "$(date): CPU: $(cat /proc/loadavg)"
    sleep 300  # Check every 5 minutes
done >> /var/log/server-health.log
```

## Notes
- This configuration prioritizes stability over power efficiency
- Suitable for dedicated server hardware with adequate cooling
- Monitor temperatures after disabling CPU power management
- Some settings may need adjustment based on specific workload requirements

## Windows 95 Flashback
*"The more things change, the more they stay the same..."*
- 1995: Disable power management to fix hardware issues
- 2025: Disable power management to fix hardware issues
- Some constants in the universe: death, taxes, and power management problems
