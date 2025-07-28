# Motherboard Audio Issue

**Status:** Open  
**Priority:** Medium  
**Created:** 2025-07-26

## Description
Motherboard audio not working. Devices show up but speaker test interface doesn't show up when they're selected.

## Investigation Steps
- [ ] Check `lspci` and `lsusb` for audio devices
- [ ] Verify ALSA configuration
- [ ] Check PulseAudio/PipeWire status
- [ ] Test with `aplay` and `speaker-test`
- [ ] Review system logs for audio-related errors

## Hardware Info
- Motherboard: [Add motherboard model]
- Audio chipset: [To be determined]

## Symptoms
- Audio devices appear in system
- Speaker test interface missing when devices selected
- No audio output

## Notes
- May be driver or configuration issue
- Could be related to audio server (PulseAudio/PipeWire)

## Related Files
- Main issue list: [Issues.md](../Issues.md)
