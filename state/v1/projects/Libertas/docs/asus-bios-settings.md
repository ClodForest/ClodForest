# ASUS ROG CROSSHAIR X870E HERO BIOS Settings Guide

**Target:** Disable all power management for server stability  
**BIOS Version:** 2.22.1284 (AMI)  
**Created:** 2025-07-28

## Critical Power Management Settings

### ✅ CONFIRMED SETTINGS
- **CPU PCIE ASMP Mode Control** → **Disabled** (User confirmed this setting exists)

### 🔍 SETTINGS TO FIND

#### Advanced Menu
Look for these sections in Advanced:

**Power Management:**
- **USB Power Management** → Disabled
- **PCIE Power Management** → Disabled  
- **Platform Power Management** → Disabled
- **Modern Standby** → Disabled (if present)

**CPU Configuration:**
- **CPU C-States** → Disabled (or find individual C1E, C3, C6 states)
- **Package C State** → Disabled
- **CPU Enhanced Halt (C1E)** → Disabled

**Onboard Devices:**
- **USB Controller Power Management** → Disabled
- **SATA Power Management** → Disabled
- **LAN Power Management** → Disabled

#### Boot Menu
- **Fast Boot** → Keep enabled (for now)

#### Monitor/Display Settings
Look for:
- **Primary Display** → Set to your main GPU connection
- **Keep Display Active** → Enabled (if available)
- **POST Delay** → 3-5 seconds (temporary for troubleshooting)

## Alternative Setting Names to Look For

ASUS uses non-standard naming. Look for these variations:

**Power Management Alternatives:**
- "ErP Ready" → Disabled
- "Energy Efficient" → Disabled  
- "Green Mode" → Disabled
- "Eco Mode" → Disabled
- "Deep Sleep" → Disabled
- "S3/S4/S5 Sleep States" → Disabled

**USB Alternatives:**
- "USB Selective Suspend" → Disabled
- "USB Legacy Support" → Enabled (paradoxically helps with power management)

**CPU Power Alternatives:**
- "Cool'n'Quiet" → Disabled
- "CPU Frequency Scaling" → Disabled

## Navigation Tips for AMI BIOS

1. **Advanced Tab** - Most power management settings
2. **Onboard Devices** - USB/SATA power settings  
3. **Boot** - Display and POST timing settings
4. **Monitor** - Hardware monitoring (temperature/fan settings)

## ASUS-Specific Features to Disable

- **ASUS Multicore Enhancement** → Manual (prevents auto-boost weirdness)
- **ASUS Performance Enhancement** → Disabled
- **AI Overclocking** → Disabled (for stability)

## Verification After Changes

1. Save settings and reboot
2. Check ethernet stability: `ip link show eth0`
3. Monitor USB errors: `dmesg | grep -i usb`
4. Check power management status: `cat /sys/module/pcie_aspm/parameters/policy`

## Notes

- AMI BIOS organization varies between motherboard models
- Some settings might be in unexpected menus
- Take photos of current settings before changing
- Change one category at a time for easier troubleshooting

## Historical Context

*"Some things never change - AMI power management was problematic in Windows 95, and here we are 30 years later still disabling the same features!"*

The more expensive the motherboard, the more power management "features" there are to break things. Your $700 board probably has dozens of power-saving options that need the axe.
