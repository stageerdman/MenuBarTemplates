# DOCK VISIBILITY — Show in Dock only while the window is open

**Date:** 2026-09-28
**Status:** OPEN

## Goal
The app should behave like a menu-bar utility that becomes a "real" app only
while its window is on screen:

- **Open the window from the menu bar** → the app appears in the **Dock** (and
  gets the normal app menu / ⌘-Tab presence).
- **Hide it back into the menu bar** (click the menu-bar icon again) → it
  **disappears from the Dock**.
- **Close the window with the red cross** → it **disappears from the Dock**.

The app keeps running in the menu bar the whole time; only its Dock presence
comes and goes.

## Background (current behavior)
`MenuBarTemplatesApp` runs as `NSApp.setActivationPolicy(.accessory)` at launch
(menu-bar only, no Dock icon). `showWindow()` just calls
`makeKeyAndOrderFront` + `activate`; it never changes the activation policy and
nothing observes the window's close button. So there is currently no Dock icon
at any time, and the menu-bar click always shows (never hides) the window.

## Design
macOS ties the Dock icon to the app's **activation policy**:
- `.regular` → Dock icon + full app menu.
- `.accessory` → menu-bar only, no Dock icon.

So the feature is: flip to `.regular` when the window becomes visible, flip back
to `.accessory` when it is hidden or closed. The window is reused
(`isReleasedWhenClosed = false`), so we react to *close* by hiding, not
destroying.

## Roadmap

### Phase 1 — Dock icon appears on open, disappears on red-cross close
- In `showWindow()`, set `NSApp.setActivationPolicy(.regular)` before
  `makeKeyAndOrderFront` / `activate`.
- Make the app delegate the window's `delegate` and implement
  `windowWillClose(_:)` → set `NSApp.setActivationPolicy(.accessory)`.
- **Verify:** open from menu bar → Dock icon appears; click red cross → Dock
  icon disappears; app still alive in the menu bar; reopening works.

### Phase 2 — Menu-bar icon toggles show/hide, with Dock in sync
- Change the left-click handler so it **toggles**: if the window is visible,
  hide it (`orderOut`) and set `.accessory`; if hidden/nil, show it and set
  `.regular`.
- Route the hide path through the same policy switch as the close path (one
  place decides policy) so "hide into menu bar" and "red cross" behave
  identically for the Dock.
- **Verify:** clicking the menu-bar icon alternately shows/hides the window and
  the Dock icon tracks it exactly.

### Phase 3 — Edge cases, polish, and a small locked-in test
- Launch with no window → stays `.accessory` (no Dock icon), as today.
- Miniaturize (yellow) keeps the window alive → decide policy: **keep
  `.regular` while minimized** (window still exists); only hide/close remove the
  Dock icon. Confirm restoring from the Dock works.
- Guard against redundant policy flips and repeated show calls.
- Extract the policy decision into a tiny pure helper
  (`isWindowVisible → desiredPolicy`) and add a `ResolverTests`-style check for
  it (AppKit window behavior itself is verified manually).
- **Verify:** run the built app and walk the full matrix
  (open / hide / close / reopen / minimize+restore / quit).

## Decisions
- _(to be filled as we build)_

## Next
- Implement Phase 1.
