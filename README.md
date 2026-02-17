# 🗄️ Claw Drive

**Google Drive stores your files. Claw Drive understands them.**

Claw Drive is an AI-managed personal drive for [OpenClaw](https://github.com/openclaw/openclaw). It auto-categorizes your files, tags them for cross-cutting search, deduplicates by content, and retrieves them in natural language — all backed by Google Drive for cloud sync and security.

## Why

Traditional file systems and cloud drives are just dumb containers. You organize everything manually, search by filename, and pray you remember where you put that tax form from last year.

Claw Drive flips this: **you hand it a file, it figures out the rest.**

- 📂 **Auto-categorize** — files sorted into the right folder without you thinking about it
- 🏷️ **Smart tagging** — cross-category search (a vet invoice is both `medical` and `invoice`)
- 🔍 **Natural language retrieval** — "find Sorbet's vet records" just works
- 🧬 **Content-aware dedup** — SHA-256 hash check prevents storing the same file twice
- ☁️ **Google Drive backend** — world-class encryption, sync, and backup under the hood
- 🔒 **Privacy-first** — sensitive categories can stay local-only or encrypt before sync

## Architecture

```
You → OpenClaw Agent → Claw Drive (AI layer)
                            │
                      ~/claw-drive/        ← local working directory
                            │
                      Google Drive sync    ← cloud backup & cross-device access
```

- **Local directory** (`~/claw-drive/`) is the source of truth
- **Google Drive** syncs it for backup, cross-device access, and sharing
- **INDEX.md** tracks every file with metadata, tags, and descriptions
- **The AI layer** (OpenClaw skill) handles categorization, tagging, dedup, and retrieval
- **Sensitive files** (`identity/`) can be excluded from sync or encrypted at rest

## Install

Clone into your OpenClaw skills directory:

```bash
git clone git@github.com:dissaozw/claw-drive.git ~/.openclaw/skills/claw-drive
```

Restart your gateway:

```bash
openclaw gateway restart
```

## Setup

Create the drive directory:

```bash
mkdir -p ~/claw-drive/{documents,finance,medical,travel,identity,receipts,contracts,photos,misc}
```

The skill creates `INDEX.md` and `.hashes` on first use.

To enable cloud sync, point Google Drive at `~/claw-drive/` (or symlink it into your Drive folder).

## Categories

| Category | Use for |
|----------|---------|
| `documents/` | General docs, letters, forms, manuals |
| `finance/` | Tax returns, bank statements, pay stubs |
| `medical/` | Health records, prescriptions, pet health |
| `travel/` | Boarding passes, itineraries, visas |
| `identity/` | ID scans, certificates (⚠️ sensitive — consider local-only) |
| `receipts/` | Purchase receipts, warranties, invoices |
| `contracts/` | Leases, employment, legal agreements |
| `photos/` | Personal photos, document scans |
| `misc/` | Anything that doesn't fit above |

## Usage

Just send a file to your OpenClaw agent. It handles:

1. **Classification** — picks the right category
2. **Naming** — descriptive, date-stamped filename
3. **Dedup** — checks if the file already exists (by content hash)
4. **Tagging** — assigns searchable tags across categories
5. **Indexing** — updates INDEX.md with metadata
6. **Reporting** — tells you what it did

To retrieve, just ask: *"find my W-2 from 2025"* or *"show all files tagged sorbet"*.

## Roadmap

- [ ] Full-text search (PDF/image text extraction at store time)
- [ ] CLI tool (`claw-drive search "tax 2025"`)
- [ ] Watch folder ingestion (auto-import from Downloads, email, etc.)
- [ ] Encrypted storage for sensitive categories
- [ ] Web dashboard for browsing and search

## License

MIT
