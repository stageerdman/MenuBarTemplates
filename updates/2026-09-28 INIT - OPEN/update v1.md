# INIT — Adopt MenuBarTemplates into AI Control

**Date:** 2026-09-28
**Status:** OPEN

## Goal
Bring the existing MenuBarTemplates app under AI Control: add the project
marker, generate `CLAUDE.md` from the global modules, and lay down the standard
scaffold — without disturbing the working code.

## Context
MenuBarTemplates is an existing, working macOS menu bar app (Swift Package
Manager; SwiftUI + AppKit + WebKit) for reusable local email templates. It
already had a GitHub remote (`stageerdman/MenuBarTemplates`, public) and a
compliant `.gitignore`, but none of the AI Control scaffold.

## Roadmap

### Phase 0 — Adoption (this update)
- [x] Classify the folder: **project** (single Swift package, not an organizer).
- [x] Add `.project` marker (modules: STRUCTURE, CODING, WORKFLOW, UX;
      secrets: none).
- [x] Generate `CLAUDE.md` from the four global modules, tuned for Swift/SPM.
- [x] Create `updates/`, `issues.txt`, and `.env` (empty — no secrets).
- [x] Confirm `.gitignore` covers `.env` (already did).
- [ ] Commit and push the adoption.

### Phase 1 — Baseline verification (next)
- [ ] Build the app (`./scripts/build-app.sh`) and run `swift run ResolverTests`
      to confirm the adopted repo builds and tests pass unchanged.
- [ ] Record baseline behavior and any warnings.

## Decisions
- Kept the **UX** module: this is a genuine user-facing macOS surface.
- Dropped no modules; all four apply.
- Left the pre-existing uncommitted edit in
  `Sources/MenuBarTemplates/HTMLBodyEditor.swift` untouched — it is a separate
  logical change and does not belong in the adoption commit.

## Next
- Decide what to do with the pending `HTMLBodyEditor.swift` edit.
- Consider a research spike for the inline-image clipboard limitation
  (see `issues.txt` and README).
