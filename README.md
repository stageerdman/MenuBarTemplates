# MenuBarTemplates

Lightweight local macOS menu bar app for reusable email templates.

## Build

Run resolver checks:

```sh
swift run ResolverTests
```

Build the app bundle:

```sh
./scripts/build-app.sh
```

Open the app:

```sh
open dist/MenuBarTemplates.app
```

## Data

Templates are stored locally at:

```text
~/Library/Application Support/MenuBarTemplates/templates.json
```

No cloud backend, accounts, or sync are used.

## Current Image Limitation

The editor preserves pasted HTML and inline images that WebKit stores in the body HTML. Copying images into Gmail or GoHighLevel depends on the receiving app's clipboard handling, especially for local or blob-backed images. The app writes HTML plus a plain-text fallback to the clipboard, but it does not upload images or create real email attachments.
