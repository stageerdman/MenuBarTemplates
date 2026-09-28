# Wiki — INIT adoption

Durable decisions and lessons from adopting MenuBarTemplates into AI Control.

## Classification: project vs organizer
- A **project** holds one piece of work (usually code); an **organizer** is a
  folder that contains *project folders* and carries `.organize`.
  MenuBarTemplates is a single Swift package with `Sources/`/`Tests/` and one
  README — a project, not an organizer.

## Adoption principles applied
- Don't disturb working code during adoption. Adoption is scaffolding only:
  `.project`, `CLAUDE.md`, `updates/`, `issues.txt`, `.env`.
- Keep the adoption commit separate from any unrelated in-flight code edits
  (one logical unit per commit).
- Respect the ecosystem's own layout (SwiftPM targets) rather than imposing a
  foreign structure.

## Project facts worth remembering
- Local-only app: data at
  `~/Library/Application Support/MenuBarTemplates/templates.json`. No backend or
  secrets — `.env` is empty and `secrets: []`.
- Core logic lives in the `EmailTemplateCore` library target; the UI is the
  `MenuBarTemplates` executable; `ResolverTests` is the check target.
- Known limitation: local/blob-backed inline images may not paste into every
  receiving app — a good candidate for an isolated research spike.
