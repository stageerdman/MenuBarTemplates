# CLAUDE.md — MenuBarTemplates

Compiled from the global AI Control modules (STRUCTURE, CODING, WORKFLOW, UX)
and tuned for this project. Regenerate with the `rebuild-claude-md` routine
when the global modules change. Local additions below the modules are preserved
across rebuilds.

MenuBarTemplates is a local macOS menu bar app (Swift Package Manager,
SwiftUI + AppKit + WebKit) for reusable email templates. No backend, accounts,
or sync — all data is local.

## Structure
- Keep the standard AI Control scaffold: `.project`, this `CLAUDE.md`,
  `.gitignore` (always covering `.env`), `.env` for secrets, `updates/`, and
  `issues.txt`.
- **Updates live in `updates/YYYY-MM-DD NAME - OPEN|CLOSED/`.** Each holds
  `update vX.md` (goal, phased roadmap, live status) and `wiki.md` (durable
  decisions and lessons). Reopen an update by flipping `CLOSED` → `OPEN`.
- **Follow Swift/SwiftPM conventions.** Sources under `Sources/<Target>/`,
  tests under `Tests/`; keep the existing target split (`EmailTemplateCore`
  library, `MenuBarTemplates` executable, `ResolverTests`). Don't impose a
  foreign layout.
- Keep it flat and simple; add folders only when the project genuinely grows
  into them.

## Coding
- **Modular for isolated context:** keep core logic in `EmailTemplateCore`
  (model, resolver) separable from the UI layer, with small explicit
  interfaces and low coupling, so any part can be understood and fixed on its
  own.
- **Minimal:** build only what's needed; prefer reuse over duplication; don't
  add abstraction on speculation.
- **Test what matters:** cover core logic and risky paths — the template
  resolver and clipboard/HTML handling especially — via `ResolverTests`. Skip
  tests for trivial glue. Most roadmap phases end with tests that lock in what
  they built.
- **Idiomatic Swift:** match the surrounding code's naming and idioms; read the
  neighbors before writing. Use standard Swift tooling and layout.

## Workflow
- **Commit AND push after every change**, one focused logical unit per commit,
  with plain honest messages. Remote is
  `github.com/stageerdman/MenuBarTemplates` — nothing important stays
  local-only. Never commit secrets; `.env` stays gitignored.
- **Non-trivial work starts with a phased roadmap** recorded in the update's
  `update vX.md`; track what's done, decided, and next as you go. Most phases
  end with tests.
- **Research spikes** for new APIs/libraries/designs run *outside* the main
  code, inside the update folder; capture findings in the update's `wiki.md`.
  (The image-in-clipboard limitation is a good spike candidate.)
- **Act as an orchestrator:** decompose and delegate to focused agents rather
  than doing everything inline.
- **Verify by running the actual app**, not just green tests, before moving on.

## UX
- This is a real user-facing macOS surface (menu bar popover, template editor).
  For UX work, **launch dedicated UX-expert agents** to think the experience
  through — several in parallel for different parts of the surface — and
  synthesize.
- **Cut everything unnecessary** (Steve Jobs style): the fewest screens,
  controls, and steps that do the job. Every element must earn its place.
- **Minimal visual system:** few fonts, a small deliberate scale for color,
  spacing, and size; follow native macOS/SwiftUI conventions rather than
  hand-rolled one-offs.
- **Reusable, isolated SwiftUI components** with clear interfaces, so each can
  be understood and restyled without touching the rest.
- Accessible by default: real contrast, keyboard reachability, sensible focus,
  meaningful labels; fast feedback and honest error states.

<!-- Local project rules below are preserved across CLAUDE.md rebuilds. -->
## Project-specific notes
- Data path: `~/Library/Application Support/MenuBarTemplates/templates.json`.
- Clipboard writes HTML + a plain-text fallback. Known limitation: local/
  blob-backed inline images may not carry into every receiving app (Gmail,
  GoHighLevel) — see README.
