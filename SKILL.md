---
name: claw-drive
description: "Claw Drive — AI-managed personal drive for OpenClaw. Auto-categorize, tag, deduplicate, and retrieve files with natural language. Backed by Google Drive for cloud sync and security. Use when receiving files to store, or when asked to find/retrieve a previously stored file."
---

# Claw Drive

Organize and retrieve personal files with auto-categorization and a searchable index.

## ⚠️ Privacy — Read This First

**File contents are personal data. Treat them accordingly.**

- **NEVER read file contents without explicit user consent.** Always ask first. Always.
- **If the user doesn't reply → default to SENSITIVE.** Silence = no consent.
- **`identity/` files are ALWAYS sensitive** — never read, never extract, never log contents.
- **Extracted content enters the conversation transcript** which is logged permanently to `.jsonl` files. Once you read a file, its contents are in the logs forever.
- **Descriptions in INDEX.md are also persistent.** Don't put sensitive details (SSNs, account numbers, passwords) in descriptions even for non-sensitive files — use redacted/partial forms (e.g. "account ending ****4321").
- **When in doubt, don't read.** A vague index entry is better than leaked personal data.

## Dependencies

- **claw-drive CLI** — `make install` from the skill directory (symlinks to `~/.local/bin/`)
- **pymupdf** — PDF text extraction (`uv run --with pymupdf` — no global install needed)
- **rclone** — Google Drive sync (optional): `brew install rclone`
- **fswatch** — file watch daemon (optional): `brew install fswatch`

## Setup

```bash
claw-drive init [path]
```

This creates the directory structure, INDEX.md, and hash ledger. Default path: `~/claw-drive`.

## Workflow

### Storing a file

When receiving a file (email attachment, Telegram upload, etc.):

1. **Privacy check** — ask the user gracefully if the file contains sensitive/personal data:
   - Something like: "Should I read the contents to index it better, or would you prefer I keep it private and just use the filename?"
   - **If user says sensitive**, or **if user doesn't reply** → treat as **sensitive** (default-safe)
   - **If user confirms it's fine to read** → proceed with full extraction
   - Files going to `identity/` are **always sensitive** — never read contents
   - Sensitive flow: classify by filename/metadata only. If that's not enough for a good description, ask the user for a brief description. Never read file contents into the conversation.

2. **Extract** (normal files only) — read file contents:
   - **PDFs:** extract text via `uv run --with pymupdf python3 -c "import pymupdf; ..."` or use the image tool
   - **Images:** use the image tool to read/describe contents
   - **Other formats:** read directly if possible
   - Pull out key entities: names, dates, amounts, account/policy numbers, addresses, etc.
3. **Classify** — determine the best category from the categories table below
4. **Name** — choose a descriptive filename: `<subject>-<detail>-<YYYY-MM-DD>.<ext>`
5. **Describe** — write a rich description using extracted content (or user-provided description for sensitive files). Include key details (dates, amounts, IDs, names) so the file is findable by any relevant search term. Don't be vague — "insurance card" is bad, "Farmers Insurance ID cards - 2024 Mercedes-Benz AMG GLC 43, Policy 525613441, effective 1/21/2026–7/21/2026" is good.
6. **Tag** — include specific tags from extracted content (model names, policy numbers, VINs, entity names) in addition to category tags
7. **Store** — run the CLI:
   ```bash
   claw-drive store <file> --category <cat> --name "clean-name.ext" --desc "Rich description with key details" --tags "tag1, tag2" --source telegram
   ```
7. **Report** — tell the user: path, category, tags, key extracted details, and what was indexed

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
```bash
# Insurance PDF — after extracting: policy 525613441, 2024 MB GLC 43, VIN, dates, agent
claw-drive store file.pdf -c insurance -n "farmers-auto-id-cards-52561-34-41.pdf" \
  -d "Farmers Insurance ID cards - 2024 Mercedes-Benz AMG GLC 43, VIN W1NKM8HB3RF183530, Policy 525613441, effective 1/21/2026–7/21/2026, agent Jiaying Su (650) 863-2544" \
  -t "insurance, auto, farmers, id-card, policy-525613441, mercedes-benz, glc-43, california" -s telegram

# Vet invoice — after extracting: clinic, amount, diagnosis, pet name
claw-drive store invoice.pdf -c medical -n "sorbet-vet-invoice-2026-02-15.pdf" \
  -d "VEG emergency visit invoice - Sorbet, $1,234.56, bronchial pattern diagnosis, prednisolone prescribed" \
  -t "medical, invoice, sorbet, emergency, vet" -s email

# W-2 — after extracting: employer, tax year, wages
claw-drive store w2.pdf -c finance -n "w2-2025.pdf" \
  -d "W-2 tax form 2025 - Employer: Acme Corp, wages $120,000" \
  -t "finance, tax-2025, w2" -s email

# Sensitive file — user said "keep it private" or didn't reply
claw-drive store scan.pdf -c identity -n "passport-scan-2026.pdf" \
  -d "Passport scan" \
  -t "identity, passport" -s telegram

# Sensitive file — user provided brief description
claw-drive store doc.pdf -c contracts -n "apartment-lease-2026.pdf" \
  -d "Apartment lease agreement, signed Jan 2026" \
  -t "contracts, lease, housing" -s email
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

## Migration

Bulk-import files from an existing directory:

```bash
# 1. Scan source directory into a plan
claw-drive migrate scan ~/messy-folder plan.json

# 2. Agent classifies each file (fills in category, name, tags, description in the JSON)

# 3. Review
claw-drive migrate summary plan.json

# 4. Dry run
claw-drive migrate apply plan.json --dry-run

# 5. Execute
claw-drive migrate apply plan.json
```

The plan JSON contains one entry per file with `category`, `name`, `tags`, `description` fields (initially null). The agent fills these in using the same extract-first approach, then `apply` copies files with full dedup and indexing.

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
- PDF text extraction: `uv run --with pymupdf python3 -c "import pymupdf; ..."`
- Use `claw-drive status` to see file counts, size, and sync status

## Privacy Checklist (every store)

Before storing any file, verify:

- [ ] Did I ask the user about privacy? (not optional)
- [ ] If no reply: am I treating it as sensitive? (must be yes)
- [ ] If sensitive: am I skipping content extraction? (must be yes)
- [ ] If `identity/`: am I skipping extraction regardless? (must be yes)
- [ ] Are there SSNs, full account numbers, or passwords in my description? (must be no)
- [ ] Would I be comfortable if this INDEX.md entry leaked? (must be yes)
