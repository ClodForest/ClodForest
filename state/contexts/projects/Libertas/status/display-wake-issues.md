# Display Wake Issues

**Status:** Reported - Needs Investigation  
**Priority:** Medium  
**Created:** 2025-07-28  

## Description
Monitors may not wake up properly after system reboots or sleep states, requiring manual intervention.

## Symptoms
- Displays remain black after system boot/reboot
- May require power cycling displays manually
- Could be related to power management settings

## Hardware Context
- **System:** ASUS ROG CROSSHAIR X870E HERO
- **GPUs:** Multiple NVIDIA cards (RTX 4080, RTX 4060 Ti)
- **Display Setup:** Multi-monitor configuration

## Potential Causes
1. **GPU Power Management:** NVIDIA power states affecting display output
2. **BIOS Display Settings:** Primary display selection issues
3. **Driver Issues:** NVIDIA driver display initialization
4. **UEFI/CSM Settings:** Legacy vs UEFI display mode conflicts

## Investigation Steps
- [ ] Check BIOS primary display settings
- [ ] Test with single monitor configuration
- [ ] Review NVIDIA driver power management settings
- [ ] Check for UEFI vs CSM display mode settings
- [ ] Monitor POST delay settings in BIOS
- [ ] Test different display connections (HDMI vs DisplayPort)

## Workarounds
- **Gaming Mode:** Enable on displays to prevent deep sleep
- **BIOS POST Delay:** Increase to 3-5 seconds for troubleshooting
- **Manual Power Cycle:** Temporary solution for wake issues

## Related Power Management
This issue may be connected to the comprehensive power management changes made to fix ethernet problems. Monitor if display issues improve with C-state and ASPM disabled.

## Next Steps
Requires dedicated troubleshooting session to identify root cause and implement permanent solution.
