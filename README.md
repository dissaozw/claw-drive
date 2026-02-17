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
- 🤖 **AI-native** — designed for [OpenClaw](https://github.com/openclaw/openclaw) agents, with a CLI under the hood

## Install

```bash
# 1. Install dependencies
brew install rclone fswatch

# 2. Clone and install
git clone git@github.com:dissaozw/claw-drive.git ~/.openclaw/skills/claw-drive
cd ~/.openclaw/skills/claw-drive
make install   # symlinks claw-drive to /usr/local/bin (or PREFIX=~/.local make install)

# 3. Initialize your drive
claw-drive init

# 4. (Optional) Set up Google Drive sync
claw-drive sync auth    # agent sends you a link to click
claw-drive sync start   # start background sync daemon
```

## Usage

Claw Drive is designed to be used through your AI agent. You don't organize files — your agent does.

### Storing files

Send a file to your agent (Telegram, email, etc.) and it handles everything:

1. **Categorizes** the file into the right folder
2. **Names** it with a descriptive, date-stamped filename
3. **Checks for duplicates** by content hash
4. **Tags** it for cross-category search
5. **Indexes** it in INDEX.md
6. **Reports** back what it did

> 📎 *"Here's Sorbet's vet invoice from today"*
>
> ✅ Stored: `medical/sorbet/sorbet-vet-invoice-2026-02-15.pdf`
> Tags: medical, invoice, sorbet, emergency
> Source: Telegram

### Retrieving files

Just ask in natural language:

> *"Find Sorbet's medical records"*
> *"Show me all invoices from January"*
> *"Do I have a copy of my W-2?"*

The agent searches INDEX.md by description, tags, path, and date — then delivers the file.

### What you never have to do

- Pick a folder
- Think of a filename
- Remember where you put something
- Manually organize anything

## CLI Reference

The CLI is the interface agents use under the hood. All commands support `--json` for machine-readable output.

| Command | Description |
|---------|-------------|
| `claw-drive init` | Initialize drive directory and INDEX.md |
| `claw-drive store <file> [opts]` | Store a file with categorization, tags, and dedup |
| `claw-drive search <query>` | Search files by description, tags, or path |
| `claw-drive list` | List all indexed files |
| `claw-drive tags` | List all tags with usage counts |
| `claw-drive status` | Show drive status (files, size, sync) |
| `claw-drive sync auth` | Authorize Google Drive (one-time, opens browser) |
| `claw-drive sync setup` | Check sync dependencies and config |
| `claw-drive sync start` | Start background sync daemon |
| `claw-drive sync stop` | Stop sync daemon |
| `claw-drive sync push` | Manual one-shot sync |
| `claw-drive sync status` | Show sync daemon state |
| `claw-drive version` | Show version |

## Sync

Optional real-time sync to Google Drive (or any rclone backend). Files sync within seconds of any change. Sensitive directories stay local-only.

See [docs/sync.md](docs/sync.md) for details.

## Architecture

```
You ← natural language → AI Agent (OpenClaw)
                              │
                        claw-drive CLI
                              │
                        ~/claw-drive/        ← local, source of truth
                              │
                        fswatch + rclone     ← optional real-time sync
                              │
                        Google Drive          ← cloud backup
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
