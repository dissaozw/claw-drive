# 🗄️ Claw Drive

Personal file vault skill for [OpenClaw](https://github.com/openclaw/openclaw). Auto-categorizes incoming files, maintains a searchable index, and retrieves them on request.

## What It Does

- **Auto-categorize** files into predefined categories (documents, finance, medical, travel, etc.)
- **Consistent naming** — descriptive, date-stamped, human-readable filenames
- **Searchable index** — `INDEX.md` as the single source of truth for all stored files
- **Retrieve on request** — find and deliver files by description, date, or category

## Install

Clone into your OpenClaw skills directory:

```bash
git clone git@github.com:dissaozw/claw-drive.git ~/.openclaw/skills/claw-drive
```

Then restart your gateway:

```bash
openclaw gateway restart
```

## Setup

Create the vault directory:

```bash
mkdir -p ~/vault/{documents,finance,medical,travel,identity,receipts,contracts,photos,misc}
```

The skill will create `~/vault/INDEX.md` on first use if it doesn't exist.

## Categories

| Category | Use for |
|----------|---------|
| `documents/` | General docs, letters, forms, manuals |
| `finance/` | Tax returns, bank statements, pay stubs |
| `medical/` | Health records, prescriptions, pet health |
| `travel/` | Boarding passes, itineraries, visas |
| `identity/` | ID scans, certificates (⚠️ sensitive) |
| `receipts/` | Purchase receipts, warranties, invoices |
| `contracts/` | Leases, employment, legal agreements |
| `photos/` | Personal photos, document scans |
| `misc/` | Anything that doesn't fit above |

## Usage

Just send a file to your OpenClaw agent — it handles classification, naming, and indexing automatically. To retrieve, ask for a file by description or category.

## License

MIT
