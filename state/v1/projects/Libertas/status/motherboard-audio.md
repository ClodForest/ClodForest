# Motherboard Audio Issue

**Status:** Open  
**Priority:** Medium  
**Created:** 2025-07-26

## Description
Motherboard audio not working. Devices show up but speaker test interface doesn't show up when they're selected.

## Investigation Steps
- [x] Check `lspci` and `lsusb` for audio devices
- [x] Verify ALSA configuration  
- [x] Check PulseAudio/PipeWire status
- [ ] Test with `aplay` and `speaker-test`
- [ ] Review system logs for audio-related errors
- [ ] Check AMD audio codec configuration
- [ ] Verify BIOS/UEFI audio settings

## Hardware Info
- Audio Controllers Found:
  - NVIDIA GPU Audio: 2 devices (cards 0,1) - HDMI working
  - AMD/ATI Audio: 1 device (card 2) - **PROBLEM: Only HDMI, no analog outputs**
  - USB Audio: Focusrite, ASUS, Anker devices working
- Audio chipset: AMD Radeon High Definition Audio Controller [Rembrandt/Strix]

## Symptoms
- Audio devices appear in system
- Speaker test interface missing when devices selected  
- No audio output
- **Root Cause Found**: AMD audio controller only shows HDMI outputs, missing analog outputs (3.5mm jacks)

## Current Status (2025-08-03)
- PipeWire running correctly (pipewire + pipewire-pulse processes active)
- AMD audio hardware detected but analog codec not initialized
- Multiple working USB and HDMI audio devices confirmed
- Issue isolated to motherboard analog audio configuration

## Detailed Diagnosis Results - UPDATED
- **Root Cause Confirmed**: AMD controller only loads HDMI codec (ATI R6xx HDMI)
- **Critical Finding**: NO separate Realtek audio controller detected in PCI scan
- **Hardware**: ASUS ROG CROSSHAIR X870E HERO - AMD X870E chipset
- **Expected**: Should have analog audio on AMD controller, but completely missing
- **Mixer Analysis**: Only PCM volume control exists, no Master/Line/Speaker controls
- **Codec Analysis**: Only digital/HDMI nodes (0x02-0x0b), zero analog pins
- **Physical Test**: Audio pipeline works (speaker-test runs without errors) but no sound output

## Key Technical Findings
- AMD audio controller missing analog codec entirely 
- No analog mixer controls available (Master, Line, Speaker, etc.)
- PipeWire sees "3 Outputs/3 Inputs" but these are HDMI ports, not analog
- All codec pins are "Digital Out at Int HDMI" - no analog pins
- Hardware working correctly: User plugged into back panel LINE OUT jack

## Next Steps - UPDATED PRIORITY
1. **BIOS Check** - ⏳ IN PROGRESS: User rebooting to verify audio settings
2. **Kernel Update** - Try newer kernel (6.1.129+ or backports 6.6+) for X870E support
3. **Force AMD analog codec** - Add kernel parameters: `snd-hda-intel.model=auto`
4. **Check ASUS documentation** - Verify if analog audio requires specific driver/firmware
5. **Last resort** - Build newer kernel from source with latest AMD audio patches

## BIOS Settings to Check
- **"HD Audio Controller"** - Enable
- **"Front Panel Audio"** - Enable  
- **"Realtek Audio"** or **"ALC Audio"** - Enable
- **"Audio Controller"** (separate from HDMI Audio) - Enable
- Location: Usually under **"Advanced → Onboard Devices"** or **"Integrated Peripherals"**

## Hardware Details
- **Motherboard**: ASUS ROG CROSSHAIR X870E HERO (Rev 1.xx)
- **Chipset**: AMD X870E (released late 2024) 
- **Kernel**: 6.1.0-17-amd64 (early 2023)
- **Issue**: Newer hardware than kernel - codec recognition problem

## Notes
- May be driver or configuration issue
- Could be related to audio server (PulseAudio/PipeWire)

## Related Files
- Main issue list: [Issues.md](../Issues.md)
