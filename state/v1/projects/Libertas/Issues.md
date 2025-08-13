# Libertas Desktop Server Issues

## Current Issues

### High Priority
* Need to make sure I have adequate heat monitoring

### Medium Priority  
* Need to make SSH tunnels to AWS VM 'vault3' persist across reboots
* Monitors may not wake properly after reboot - require manual intervention
* Ongoing power management optimization and monitoring

### Low Priority
* When windows are full-screen and my focus-follows-mouse activates them, they get auto-raised. Normal windows, even maximized ones, correctly remain un-raised.
* Single USB device causing descriptor read errors

## Resolved Issues

* ✅ **Ethernet Interface Loss** - PCIe ASPM compatibility issue resolved (2025-07-28)
* ✅ **Motherboard Audio** - User error: wrong device selected in GUI (2025-08-03)

## Issue Status

### Open Issues
- [Heat Monitoring](status/heat-monitoring.md) - High Priority
- [SSH Tunnel Persistence](status/ssh-tunnel-persistence.md) - Medium Priority  
- [Display Wake Issues](status/display-wake-issues.md) - Medium Priority
- [Power Management Monitoring](status/power-management-monitoring.md) - Medium Priority
- [Fullscreen Focus Raising](status/fullscreen-focus-raising.md) - Low Priority
- [USB Descriptor Errors](status/usb-descriptor-errors.md) - Low Priority

### Resolved Issues
- [Ethernet Interface](status/ethernet-interface.md) - ✅ Resolved (2025-07-28)
- [Motherboard Audio](status/motherboard-audio.md) - ✅ Resolved (2025-08-03)

## Notes

Created: 2025-07-26
Last Updated: 2025-08-03
