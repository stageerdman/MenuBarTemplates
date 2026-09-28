# APP ICON — Copy/paste glyph on a white tile

**Date:** 2026-09-28
**Status:** OPEN

## Goal
Give the app a recognizable Dock/Finder icon: a **copy-paste** glyph on a
**white** background, so it's easy to spot in the Dock (which it now enters when
the window is open — see the DOCK VISIBILITY update).

## Design
- White rounded-rect (squircle, ~22.37% corner radius) with a small transparent
  margin, so it shows as a clean white tile in the Dock.
- SF Symbol `doc.on.clipboard` (document + clipboard = copy/paste), semibold, in
  a near-black slate (`#212933`) for strong contrast on white.
- Rendered offscreen with AppKit at all 10 iconset sizes (16→1024) and packed
  into `AppIcon.icns` with `iconutil`. No external tools or design assets.

## What changed
- **`scripts/make-icon.sh`** — reproducible generator (embedded Swift/AppKit).
  Design knobs (symbol, colors, padding, glyph scale) are variables at the top.
- **`Resources/AppIcon.icns`** — the generated icon, committed so builds don't
  depend on regeneration.
- **`scripts/build-app.sh`** — copies `AppIcon.icns` into
  `Contents/Resources/` and adds `CFBundleIconFile = AppIcon` to `Info.plist`.

## Verification
- [x] `make-icon.sh` produces a valid `.icns` (`file` reports a Mac OS X icon);
      512px preview inspected — reads clearly as copy/paste on white.
- [x] `build-app.sh` embeds the icon; `CFBundleIconFile` present in Info.plist.
- [ ] **Human visual check (pending):** open the window and confirm the white
      copy/paste icon shows in the Dock (and on the .app in Finder).

## Decisions
- Chose `doc.on.clipboard` over `doc.on.doc`: the clipboard reads as "paste"
  while the document reads as "copy", matching what the app does.
- Committed the rendered `.icns` rather than generating it during every build —
  keeps `build-app.sh` fast and offline; regenerate only when the design
  changes via `scripts/make-icon.sh`.

## Next
- Human confirms the Dock icon, then flip `OPEN` → `CLOSED`. Easy tweaks if
  wanted: glyph color, weight, or switch to `doc.on.doc` (edit make-icon.sh).
