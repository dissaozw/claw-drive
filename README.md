# 🗄️ Claw Drive

**Google Drive stores your files. Claw Drive understands them.**

[![License: MIT](https://img.shields.io/badge/License-MIT-ffd60a?style=flat-square)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-supported-0078d7?logo=apple&logoColor=white&style=flat-square)](https://www.apple.com/macos/)
[![Shell](https://img.shields.io/badge/Shell-bash-4EAA25?logo=gnubash&logoColor=white&style=flat-square)](https://www.gnu.org/software/bash/)

Claw Drive is an AI-managed personal drive. It auto-categorizes your files, tags them for cross-cutting search, deduplicates by content, and retrieves them in natural language — all backed by Google Drive for cloud sync and security.

## Features

- 📂 **Auto-categorize** — files sorted into the right folder without you thinking about it
- 🏷️ **Smart tagging** — cross-category search (a vet invoice is both `medical` and `invoice`)
- 🔍 **Natural language retrieval** — "find Sorbet's vet records" just works
- 🧬 **Content-aware dedup** — SHA-256 hash check prevents storing the same file twice
- ☁️ **Google Drive sync** — optional real-time backup via fswatch + rclone
- 🔒 **Privacy-first** — local-first by default, sensitive categories excluded from sync
- 🤖 **AI + CLI** — works as an [OpenClaw](https://github.com/openclaw/openclaw) skill or standalone CLI

## Install

### From source

```bash
git clone git@github.com:dissaozw/claw-drive.git
cd claw-drive
make install
```

### Initialize

```bash
claw-drive init
```

Creates `~/claw-drive/` with category folders and INDEX.md.

## Quick Start

```bash
# Store a file with category, description, and tags
claw-drive store invoice.pdf \
  --category finance \
  --desc "Q4 2025 consulting invoice" \
  --tags "finance, invoice, consulting" \
  --source email

# Search by any field
claw-drive search "consulting"
claw-drive search "invoice"

# List all files
claw-drive list

# List all tags with usage counts
claw-drive tags

# Show drive status
claw-drive status
```

## Commands

| Command | Description |
|---------|-------------|
| `claw-drive init` | Initialize drive directory and INDEX.md |
| `claw-drive store <file> [opts]` | Store a file with categorization, tags, and dedup |
| `claw-drive search <query>` | Search files by description, tags, or path |
| `claw-drive list` | List all indexed files |
| `claw-drive tags` | List all tags with usage counts |
| `claw-drive status` | Show drive status (files, size, sync) |
| `claw-drive sync setup` | Check sync dependencies and config |
| `claw-drive sync start` | Start background sync daemon |
| `claw-drive sync stop` | Stop sync daemon |
| `claw-drive sync push` | Manual one-shot sync |
| `claw-drive sync status` | Show sync daemon state |
| `claw-drive version` | Show version |

All commands support `--json` for machine-readable output.

## Sync

Optional real-time sync to Google Drive (or any rclone backend):

```bash
# Install dependencies
brew install rclone fswatch
rclone config  # set up remote

# Configure
cat > ~/claw-drive/.sync-config <<EOF
backend: google-drive
remote: gdrive:claw-drive
exclude:
  - identity/
  - .hashes
EOF

# Start daemon
claw-drive sync setup
claw-drive sync start
```

Files sync within seconds of any change. Sensitive directories stay local-only.

See [docs/sync.md](docs/sync.md) for details.

## Architecture

```
You → claw-drive CLI (or OpenClaw agent)
            │
      ~/claw-drive/           ← local, always the source of truth
            │
      fswatch + rclone        ← optional real-time sync
            │
      Google Drive             ← cloud backup + cross-device access
```

## Categories

| Category | Use for |
|----------|---------|
| `documents/` | General docs, letters, forms, manuals |
| `finance/` | Tax returns, bank statements, pay stubs |
| `medical/` | Health records, prescriptions, pet health |
| `travel/` | Boarding passes, itineraries, visas |
| `identity/` | ID scans, certificates (⚠️ sensitive — excluded from sync) |
| `receipts/` | Purchase receipts, warranties, invoices |
| `contracts/` | Leases, employment, legal agreements |
| `photos/` | Personal photos, document scans |
| `misc/` | Anything that doesn't fit above |

## Documentation

- [Tags](docs/tags.md) — tagging guidelines and examples
- [Sync](docs/sync.md) — Google Drive sync setup and daemon
- [Security](docs/security.md) — threat model and privacy controls

## Roadmap

- [ ] Full-text search (PDF/image text extraction at store time)
- [ ] Watch folder ingestion (auto-import from Downloads)
- [ ] Encrypted storage for sensitive categories
- [ ] Linux support (inotifywait + systemd)
- [ ] Web dashboard for browsing and search
- [ ] Homebrew tap distribution

## License

[MIT](LICENSE)
