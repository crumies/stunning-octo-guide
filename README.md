# Aptum Dashboard 4.3 — Icon + Live Activity + HUD options

Fixes:
- App icon regenerated from the uploaded triangle logo as fully opaque RGB PNGs.
- Explicit AppIcon asset catalog setup.
- Build workflow now verifies Assets.car exists in the built app.
- Added Live Activity files for Lock Screen / Dynamic Island speed, kW, battery, RPM and temp.
- Added HUD customization toggles:
  - kW
  - temperatures
  - lean meter
  - graphs
  - status icons
- Added RPM/speed redline gradient arc.
- Motor icon changed to a display-style block icon.
- App still keeps Aptum text logo inside the app.

Important:
- Delete the old app from iPhone before installing the new IPA.
- If iOS caches the old icon, reboot the phone after installing.
- Live Activity requires iOS 16.1+ and needs the widget extension target built with the app.
