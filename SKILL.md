---
name: claw-drive
description: "Claw Drive — AI-managed personal drive for OpenClaw. Auto-categorize, tag, deduplicate, and retrieve files with natural language. Backed by Google Drive for cloud sync and security. Use when receiving files to store, or when asked to find/retrieve a previously stored file."
---

# Claw Drive

Organize and retrieve personal files with auto-categorization and a searchable index.

## Setup

Create the vault directory structure:

```bash
mkdir -p ~/claw-drive/{documents,finance,medical,travel,identity,receipts,contracts,photos,misc}
```

Create `~/claw-drive/INDEX.md`:

```markdown
# 📁 Claw Drive — Personal File Index

## Directory Structure
- **documents/** — general docs, letters, forms
- **finance/** — tax, bank statements, investment docs
- **medical/** — health records, insurance, prescriptions
- **travel/** — tickets, itineraries, visas, bookings
- **identity/** — ID scans, certificates (⚠️ sensitive)
- **receipts/** — purchase receipts, warranties, invoices
- **contracts/** — leases, employment, legal agreements
- **photos/** — personal photos, scans
- **misc/** — anything that doesn't fit above

## File Index

| Date | Path | Description | Tags | Source |
|------|------|-------------|------|--------|

---
*Last updated: YYYY-MM-DD*
```

Override the path in `TOOLS.md` if not using `~/claw-drive/`.

## Workflow

### Storing a file

When receiving a file (email attachment, Telegram upload, etc.):

1. **Classify** — determine the best category from the directory structure
2. **Name** — give it a descriptive filename: `<subject>-<detail>-<YYYY-MM-DD>.<ext>`
3. **Copy** — `cp <source> ~/claw-drive/<category>/<descriptive-name>`
4. **Tag** — assign 1-5 relevant tags (see Tagging below)
5. **Index** — append a row to `~/claw-drive/INDEX.md`:
   ```
   | YYYY-MM-DD | category/filename | Brief description | tag1, tag2 | Source |
   ```
6. **Report** — tell the user: path, category, tags, and what was indexed

### Retrieving a file

When asked to find a file:

1. **Search INDEX.md** — grep or scan the index table by description, tags, path, or date
2. **Verify** — confirm the file exists at the listed path
3. **Deliver** — send via message tool or provide the path

### Tagging

Tags add cross-category searchability. A file lives in one folder but can have multiple tags.

**Guidelines:**
- 1-5 tags per file, comma-separated in the Tags column
- Lowercase, single words or short hyphenated phrases
- Always include the category name as a tag (e.g. `medical` for files in `medical/`)
- Add cross-cutting tags for things like: entity names (`sorbet`), document type (`invoice`, `receipt`, `report`), context (`emergency`, `tax-2025`)
- Reuse existing tags when possible — check INDEX.md before inventing new ones

**Examples:**
```
| 2026-02-15 | medical/sorbet-vet-invoice-2026-02-15.pdf | VEG emergency visit invoice | medical, invoice, sorbet, emergency | email |
| 2026-01-20 | finance/w2-2025.pdf | W-2 tax form 2025 | finance, tax-2025 | email |
| 2026-02-10 | travel/japan-itinerary-2026-03.pdf | Tokyo trip itinerary | travel, japan | telegram |
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
| medical | Health records, lab results, prescriptions, pet health |
| travel | Boarding passes, itineraries, hotel bookings, visas |
| identity | Passport scans, birth certs, SSN docs (⚠️ sensitive) |
| receipts | Purchase receipts, warranties, service invoices |
| contracts | Leases, employment agreements, legal docs |
| photos | Personal photos, document scans |
| misc | Anything that doesn't fit above |

**When in doubt:** `misc/` is fine. Better to store it somewhere than not at all.

### Deduplication

Before storing a file, check for duplicates:

1. **Hash** — compute SHA-256: `shasum -a 256 <file>`
2. **Check** — search `~/claw-drive/.hashes` for a match
3. **If duplicate** — tell the user the file already exists at the original path. Don't store again.
4. **If new** — store normally, then append to `~/claw-drive/.hashes`:
   ```
   <sha256>  <category/filename>
   ```

Create `~/claw-drive/.hashes` on first use if it doesn't exist.

**Note:** Dedup is content-based (hash), not name-based. Same file with different names = duplicate. Different files with same name = both stored.

## Tips

- Always update INDEX.md when adding files — it's the single source of truth
- For sensitive files (identity/), note that in the index but don't describe contents in detail
- PDF text extraction: `uv run --with pymupdf python3 -c "import pymupdf; ..."`
- Claw Drive is local-only — don't sync sensitive categories to cloud storage
