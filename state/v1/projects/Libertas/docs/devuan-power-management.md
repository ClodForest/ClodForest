# Devuan-Specific Power Management Configuration

**Target System:** Devuan (Debian without systemd)  
**Init System:** SysV init or OpenRC  
**Created:** 2025-07-28

## Key Differences from Systemd Systems

### 1. Disable Suspend/Hibernate (Devuan Method)
Instead of `systemctl mask`, edit `/etc/sleep.conf` or remove/disable:
```bash
# Check what's handling power management
ls -la /etc/acpi/
ls -la /etc/pm/

# Disable suspend/hibernate in ACPI
sudo chmod -x /etc/acpi/sleep.sh 2>/dev/null || true
sudo chmod -x /etc/acpi/hibernate.sh 2>/dev/null || true

# Or edit /etc/systemd/logind.conf if present (some Devuan installs have parts)
# HandleSuspendKey=ignore
# HandleHibernateKey=ignore
```

### 2. Network Interface Power Management
Add to `/etc/rc.local` (runs at boot):
```bash
# Before exit 0, add:
ethtool -s eth0 wol d 2>/dev/null || true
echo 'on' > /sys/class/net/eth0/device/power/control 2>/dev/null || true
```

### 3. Service Management
Use `service` or `update-rc.d` instead of `systemctl`:
```bash
# Check running services
service --status-all

# Disable power management services if present
update-rc.d acpi-support disable 2>/dev/null || true
update-rc.d pm-utils disable 2>/dev/null || true
```

## Quick Implementation for Right Now

### Step 1: GRUB First (Most Important)
```bash
sudo nano /etc/default/grub
# Add the PCIe parameters to existing line:
GRUB_CMDLINE_LINUX_DEFAULT="quiet pcie_port_pm=off pcie_aspm.policy=performance"

sudo update-grub
```

### Step 2: Basic Network Protection
```bash
sudo nano /etc/rc.local
# Add before exit 0:
ethtool -s eth0 wol d
echo 'on' > /sys/class/net/eth0/device/power/control
```

That's the minimum for your first reboot test. We can layer on the rest after you confirm the ethernet issue is fixed.

## What to Push to ClodForest
Your updated documentation is already saved:
- `docs/hardware.md` 
- `docs/software.md`
- `docs/server-power-management.md` (I'll update for Devuan)
- `status/ethernet-interface.md`

Quick git commands before you switch:
```bash
cd /mnt/nvme0n1p4/git/github/ClodForest/ClodForest
git add state/contexts/projects/Libertas/
git commit -m "Document ethernet interface issue and power management solutions"
git push
```

Go handle your laptop switch and I'll have the full Devuan-specific implementation ready when you get back. The GRUB change alone should fix your ethernet issue - everything else is just insurance against future power management shenanigans.

Real job first, server stability second, but at least you'll have a diagnosis and plan! 🚀