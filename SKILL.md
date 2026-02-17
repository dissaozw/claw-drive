---
name: claw-drive
description: "Claw Drive — AI-managed personal drive for OpenClaw. Auto-categorize, tag, deduplicate, and retrieve files with natural language. Backed by Google Drive for cloud sync and security. Use when receiving files to store, or when asked to find/retrieve a previously stored file."
---

# Claw Drive

Organize and retrieve personal files with auto-categorization and a searchable index.

## Setup

```bash
claw-drive init [path]
```

This creates the directory structure, INDEX.md, and hash ledger. Default path: `~/claw-drive`.

## Workflow

### Storing a file

When receiving a file (email attachment, Telegram upload, etc.):

1. **Classify** — determine the best category from the categories table below
2. **Name** — choose a descriptive filename: `<subject>-<detail>-<YYYY-MM-DD>.<ext>`
3. **Store** — run the CLI:
   ```bash
   claw-drive store <file> --category <cat> --name "clean-name.ext" --desc "Brief description" --tags "tag1, tag2" --source telegram
   ```
4. **Report** — tell the user: path, category, tags, and what was indexed

The CLI handles copying, hashing, deduplication, and index updates automatically. If the file is a duplicate, it will be rejected.

The `--name` flag lets you override the original filename (which may be ugly like `file_17---8c1ee63d-...`) with a clean, descriptive name.

### Retrieving a file

When asked to find a file:

1. **Search** — `claw-drive search "<query>"` searches descriptions, tags, and paths
2. **List** — `claw-drive list` shows all indexed files
3. **Tags** — `claw-drive tags` shows all tags with usage counts
4. **Deliver** — send via message tool or provide the path

### Tagging

Tags add cross-category searchability. A file lives in one folder but can have multiple tags.

**Guidelines:**
- 1-5 tags per file, comma-separated
- Lowercase, single words or short hyphenated phrases
- Always include the category name as a tag (e.g. `medical` for files in `medical/`)
- Add cross-cutting tags for things like: entity names (`sorbet`), document type (`invoice`, `receipt`, `report`), context (`emergency`, `tax-2025`)
- Reuse existing tags when possible — check `claw-drive tags` before inventing new ones

**Examples:**
```
claw-drive store invoice.pdf -c medical -n "sorbet-vet-invoice-2026-02-15.pdf" -d "VEG emergency visit invoice" -t "medical, invoice, sorbet, emergency" -s email
claw-drive store w2.pdf -c finance -n "w2-2025.pdf" -d "W-2 tax form 2025" -t "finance, tax-2025" -s email
claw-drive store itinerary.pdf -c travel -n "japan-itinerary-2026-03.pdf" -d "Tokyo trip itinerary" -t "travel, japan" -s telegram
```

### Naming conventions

- Lowercase, hyphens between words: `sorbet-vet-invoice-2026-02-15.pdf`
- Include date when relevant
- Include subject/entity name for clarity
- Keep it human-readable — no UUIDs or timestamps

### Categories

| Category | Use for |
|----------|---------|
| documents | General docs, letters, forms, manuals |
| finance | Tax returns, bank statements, investment docs, pay stubs |
| insurance | Insurance policies, claims, coverage documents |
| medical | Health records, lab results, prescriptions, pet health |
| travel | Boarding passes, itineraries, hotel bookings, visas |
| identity | Passport scans, birth certs, SSN docs (⚠️ sensitive) |
| receipts | Purchase receipts, warranties, service invoices |
| contracts | Leases, employment agreements, legal docs |
| photos | Personal photos, document scans |
| misc | Anything that doesn't fit above |

**When in doubt:** `misc/` is fine. Better to store it somewhere than not at all.

## Sync (Optional)

Claw Drive can auto-sync to Google Drive (or any rclone-supported backend) via a background daemon.

### Prerequisites

```bash
brew install rclone fswatch
```

### Authorization

Run `claw-drive sync auth`. It opens a browser on the machine for Google sign-in.

**Agent behavior during auth:**
1. Run `claw-drive sync auth` in background
2. Try the OpenClaw browser tool to click through the Google consent screen
3. If browser tool is unavailable, send the auth URL to the user and ask them to complete sign-in on the machine (e.g. via Screen Sharing)
4. Wait for rclone to capture the token

### Commands

```bash
claw-drive sync setup   # verify deps and config
claw-drive sync start   # start background daemon (fswatch + rclone)
claw-drive sync stop    # stop daemon
claw-drive sync push    # manual one-shot sync
claw-drive sync status  # show sync status
```

The daemon watches the drive directory for file changes and syncs to the remote within seconds. It runs as a launchd service — starts on login, restarts on failure.

Logs: `~/Library/Logs/claw-drive/sync.log`

### Per-category privacy

Use the `exclude` list in `.sync-config` to keep sensitive directories local-only. `identity/` is excluded by default.

## Tips

- The CLI maintains INDEX.md automatically — don't edit it manually
- For sensitive files (identity/), note that in the index but don't describe contents in detail
- PDF text extraction: `uv run --with pymupdf python3 -c "import pymupdf; ..."`
- Use `claw-drive status` to see file counts, size, and sync status
