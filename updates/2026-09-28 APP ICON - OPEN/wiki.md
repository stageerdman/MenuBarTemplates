# Wiki — App icon generation

How to give a manually-bundled (non-Xcode) macOS app an icon.

## Bundle wiring
- For a hand-built `.app` (no asset catalog), put `AppIcon.icns` in
  `Contents/Resources/` and set `CFBundleIconFile` = `AppIcon` (no extension) in
  `Info.plist`. That's all macOS needs to show it in Dock/Finder.
- `.icns` is built from an `.iconset` folder with `iconutil -c icns`. The folder
  must contain the standard names: `icon_16x16.png`, `icon_16x16@2x.png`,
  `icon_32x32.png`, `icon_32x32@2x.png`, `icon_128x128.png`,
  `icon_128x128@2x.png`, `icon_256x256.png`, `icon_256x256@2x.png`,
  `icon_512x512.png`, `icon_512x512@2x.png` (16→1024 px).

## Rendering with AppKit (no design tools)
- `NSImage.lockFocus()` gives an offscreen context that works in a normal user
  session (confirmed here) — no window server app needed.
- SF Symbols are template images; tint by drawing the symbol, then filling with
  `.compositingOperation = .sourceAtop`. Tint in a **separate** NSImage buffer,
  then composite that over the background — tinting in place would also paint
  the background where it's opaque.
- Apple's squircle corner radius is ~22.37% of the side. A small transparent
  margin (~6%) keeps the tile from touching the icon edges.

## Gotchas
- Dock/Finder cache icons aggressively. `touch`-ing the `.app` and relaunching
  usually refreshes; a full reset is `killall Dock`.
- This app only shows a Dock icon while its window is open (activation policy
  toggle — see the DOCK VISIBILITY update), so the icon appears on open, not at
  launch.
