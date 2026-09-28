# Wiki — Dock visibility

Durable knowledge for making a menu-bar app show a Dock icon only while its
window is open.

## The core mechanism
- The Dock icon and ⌘-Tab presence are controlled by
  `NSApplication.activationPolicy`, not by the window itself.
  - `.regular` → Dock icon + normal app menu.
  - `.accessory` → menu-bar only, no Dock icon (the app's launch state here).
  - `.prohibited` → not used.
- Toggle at runtime with `NSApp.setActivationPolicy(.regular / .accessory)`.
  Switching to `.regular` usually needs a follow-up
  `NSApp.activate(ignoringOtherApps: true)` for the window to come forward.

## Reacting to the red cross
- The window is created with `isReleasedWhenClosed = false`, so closing it hides
  it rather than deallocating — we reuse the same `NSWindow`.
- To catch the close, set the app delegate as the window's `delegate` and
  implement `windowWillClose(_:)`; that's where we drop back to `.accessory`.
  (`windowShouldClose` is for veto/confirmation, not the right hook here.)

## Show/hide toggle
- "Hide into the menu bar" = `window.orderOut(nil)` (keeps it alive, off screen)
  plus `.accessory`. This mirrors the red-cross path, so both should funnel
  through one policy decision to avoid drift.

## Gotchas / decisions
- Keep `.regular` while the window is only **minimized** (yellow) — the window
  still exists and lives in the Dock's minimized area; forcing `.accessory`
  there would fight macOS.
- Avoid redundant `setActivationPolicy` calls; flip only on real transitions.
- Launch state stays `.accessory` so the app starts as a pure menu-bar tool
  with no Dock icon until the user opens the window.
