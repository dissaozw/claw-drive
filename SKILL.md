---
name: vault
description: Personal file vault — auto-categorize incoming files, maintain an index, and retrieve on request. Use when receiving files to store, or when asked to find/retrieve a previously stored file.
---

# Vault

Organize and retrieve personal files with auto-categorization and a searchable index.

## Setup

Create the vault directory structure:

```bash
mkdir -p ~/vault/{documents,finance,medical,travel,identity,receipts,contracts,photos,misc}
```

Create `~/vault/INDEX.md`:

```markdown
# 📁 Vault — Personal File Index

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

| Date | Path | Description | Source |
|------|------|-------------|--------|

---
*Last updated: YYYY-MM-DD*
```

Override the vault path in `TOOLS.md` if not using `~/vault/`.

## Workflow

### Storing a file

When receiving a file (email attachment, Telegram upload, etc.):

1. **Classify** — determine the best category from the directory structure
2. **Name** — give it a descriptive filename: `<subject>-<detail>-<YYYY-MM-DD>.<ext>`
3. **Copy** — `cp <source> ~/vault/<category>/<descriptive-name>`
4. **Index** — append a row to `~/vault/INDEX.md`:
   ```
   | YYYY-MM-DD | category/filename | Brief description | Source (email, telegram, etc.) |
   ```
5. **Report** — tell the user: path, category, and what was indexed

### Retrieving a file

When asked to find a file:

1. **Search INDEX.md** — grep or scan the index table
2. **Verify** — confirm the file exists at the listed path
3. **Deliver** — send via message tool or provide the path

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

## Tips

- Always update INDEX.md when adding files — it's the single source of truth
- For sensitive files (identity/), note that in the index but don't describe contents in detail
- PDF text extraction: `uv run --with pymupdf python3 -c "import pymupdf; ..."`
- The vault is local-only — don't sync sensitive categories to cloud storage
