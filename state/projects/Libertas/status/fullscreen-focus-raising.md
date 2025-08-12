# Fullscreen Window Focus Raising Issue

**Status:** Open  
**Priority:** Low  
**Created:** 2025-07-26

## Description
When windows are full-screen and my focus-follows-mouse activates them, they get auto-raised. Normal windows, even maximized ones, correctly remain un-raised.

## Investigation Steps
- [ ] Check window manager settings
- [ ] Review focus-follows-mouse configuration
- [ ] Test behavior with different window managers
- [ ] Check for auto-raise settings specific to fullscreen windows

## Environment Info
- Window Manager: [Add WM details]
- Desktop Environment: [Add DE details]
- Focus policy: focus-follows-mouse

## Expected Behavior
- Fullscreen windows should not auto-raise on focus
- Only focus should change, not Z-order

## Actual Behavior
- Fullscreen windows auto-raise when focused via mouse
- Maximized windows behave correctly (no auto-raise)

## Notes
- This affects workflow when using multiple monitors
- May be configurable in window manager settings

## Related Files
- Main issue list: [Issues.md](../Issues.md)
