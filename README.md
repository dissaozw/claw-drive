# 🗄️ Claw Drive

**Google Drive stores your files. Claw Drive understands them.**

[![License: MIT](https://img.shields.io/badge/License-MIT-ffd60a?style=flat-square)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-supported-0078d7?logo=apple&logoColor=white&style=flat-square)](https://www.apple.com/macos/)
[![Shell](https://img.shields.io/badge/Shell-bash-4EAA25?logo=gnubash&logoColor=white&style=flat-square)](https://www.gnu.org/software/bash/)
[![CI](https://github.com/dissaozw/claw-drive/actions/workflows/ci.yml/badge.svg)](https://github.com/dissaozw/claw-drive/actions/workflows/ci.yml)

Claw Drive is an AI-managed personal drive. It auto-categorizes your files, tags them for cross-cutting search, deduplicates by content, and retrieves them in natural language — all backed by Google Drive for cloud sync and security.

**Privacy is not a feature — it's the foundation.** Your agent never reads file contents without asking. If you don't respond, it defaults to private. Sensitive categories like `identity/` are never read, never synced. Your data stays yours.

## Features

- 📂 **Auto-categorize** — files sorted into the right folder without you thinking about it
- 🏷️ **Smart tagging** — cross-category search (a vet invoice is both `medical` and `invoice`)
- 🔍 **Natural language retrieval** — "find my cat's vet records" just works
- 🧬 **Content-aware dedup** — SHA-256 hash check prevents storing the same file twice
- ☁️ **Google Drive sync** — optional real-time backup via fswatch + rclone
- 🔒 **Privacy-first** — local-first by default, sensitive categories excluded from sync, default-safe content handling
- 🛡️ **Sensitive file protection** — agent asks before reading contents; defaults to private if no reply
- 🤖 **AI-native** — designed for [OpenClaw](https://github.com/openclaw/openclaw) agents, with a CLI under the hood

## Install

```bash
# 1. Install dependencies
brew install rclone fswatch   # optional, for sync only
# pymupdf for PDF extraction — runs via uv, no global install needed

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

1. **Asks about privacy** — "Should I read the contents, or keep it private?"
2. **Extracts content** (if permitted) — reads PDFs, images, docs to pull out key details
3. **Categorizes** the file into the right folder
4. **Names** it with a descriptive, date-stamped filename
5. **Checks for duplicates** by content hash
6. **Tags** it for cross-category search with specific identifiers
7. **Indexes** it in INDEX.md with a rich, searchable description
8. **Reports** back what it did

> 📎 *"Here's my auto insurance card"*
>
> 🔒 *"Should I read the contents to index it better, or keep it private?"*
>
> 👤 *"Go ahead"*
>
> ✅ Stored: `insurance/acme-auto-id-cards.pdf`
> Policy ****3441 · 2024 Honda Civic · Effective 1/21/2026–7/21/2026
> Tags: insurance, auto, acme, honda-civic, california

If you don't reply or say it's sensitive, the agent classifies by filename only and asks for a brief description if needed. Your data is never read without consent.

### Retrieving files

Just ask in natural language:

> *"Find my cat's medical records"*
> *"Show me all invoices from January"*
> *"Do I have a copy of my W-2?"*

The agent reads INDEX.md directly — its semantic understanding beats any grep. It finds files by meaning, not string matching.

### What you never have to do

- Pick a folder
- Think of a filename
- Remember where you put something
- Manually organize anything

## CLI Reference

The CLI handles **write operations** — store, sync, migrate — where atomicity matters (dedup + index updates). For **read operations** (search, list, tags), the agent reads INDEX.md directly.

| Command | Description |
|---------|-------------|
| `claw-drive init` | Initialize drive directory and INDEX.md |
| `claw-drive store <file> [opts]` | Store a file with categorization, tags, dedup, and optional rename (`--name`) |
| `claw-drive status` | Show drive status (files, size, sync) |
| `claw-drive sync auth` | Authorize Google Drive (one-time, opens browser) |
| `claw-drive sync setup` | Check sync dependencies and config |
| `claw-drive sync start` | Start background sync daemon |
| `claw-drive sync stop` | Stop sync daemon |
| `claw-drive sync push` | Manual one-shot sync |
| `claw-drive sync status` | Show sync daemon state |
| `claw-drive migrate scan <dir> [plan.json]` | Scan a directory into a migration plan |
| `claw-drive migrate summary [plan.json]` | Show migration plan breakdown |
| `claw-drive migrate apply [plan.json] [--dry-run]` | Execute migration plan |
| `claw-drive version` | Show version |

## Sync

Optional real-time sync to Google Drive (or any rclone backend). Files sync within seconds of any change. Sensitive directories stay local-only.

See [docs/sync.md](docs/sync.md) for details.

## Migration

Got a messy folder full of unsorted files? Claw Drive's migration workflow handles it:

```bash
# 1. Scan the source directory
claw-drive migrate scan ~/messy-folder migration-plan.json

# 2. AI agent classifies each file (fills in category, name, tags, description)

# 3. Review the plan
claw-drive migrate summary migration-plan.json

# 4. Dry run first
claw-drive migrate apply migration-plan.json --dry-run

# 5. Execute
claw-drive migrate apply migration-plan.json
```

The scan outputs a JSON plan with file metadata (path, size, mime type, extension). The agent fills in classification fields, then `apply` copies files into Claw Drive with full dedup, indexing, and tagging.

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
| `insurance/` | Policies, ID cards, claims, coverage docs |
| `medical/` | Health records, prescriptions, pet health |
| `travel/` | Boarding passes, itineraries, visas |
| `identity/` | ID scans, certificates (⚠️ sensitive — excluded from sync) |
| `receipts/` | Purchase receipts, warranties, invoices |
| `contracts/` | Leases, employment, legal agreements |
| `photos/` | Personal photos, document scans |
| `misc/` | Anything that doesn't fit above |

## Privacy & Security

**Claw Drive treats your files as personal data by default.** This isn't an afterthought — it's a core design decision.

### The Problem

AI agents that read your files put those contents into conversation transcripts — which are logged permanently. A "helpful" agent that reads your passport scan, tax return, or medical record has now copied that data into a `.jsonl` log file. That's a leak, not a feature.

### The Solution

Claw Drive's agent **always asks before reading**. And if you don't answer, it assumes the answer is no.

| Scenario | Behavior |
|----------|----------|
| User says "go ahead" | Full content extraction → rich description + specific tags |
| User says "keep it private" | Filename-only classification, asks for brief description |
| **User doesn't reply** | **Defaults to sensitive** — no content reading |
| **File goes to `identity/`** | **Always sensitive** — contents never read, never synced |

### What "sensitive" means in practice

- File contents are **never read** by the agent
- Classification uses **filename and user input only**
- INDEX.md descriptions are kept **generic** (no SSNs, account numbers, etc.)
- `identity/` is **excluded from cloud sync** by default
- The file is still stored, hashed (for dedup), tagged, and indexed — just without content extraction

### Defense in depth

| Layer | Protection |
|-------|-----------|
| Consent | Agent asks before reading any file |
| Default-safe | No reply = sensitive |
| Category rules | `identity/` always sensitive, excluded from sync |
| Sync exclusion | `.sync-config` exclude list for any category |
| Index hygiene | No raw sensitive data in descriptions |
| Local-first | Cloud sync is optional, not default |

## Documentation

- [Tags](docs/tags.md) — tagging guidelines and examples
- [Sync](docs/sync.md) — Google Drive sync setup and daemon
- [Security](docs/security.md) — threat model and privacy controls

## Roadmap

- [ ] `update` command — modify description/tags on existing entries
- [ ] `delete` command — remove files with atomic index cleanup
- [ ] Watch folder ingestion (auto-import from Downloads)
- [ ] Encrypted storage for sensitive categories
- [ ] Linux support (inotifywait + systemd)
- [ ] Web dashboard for browsing and search
- [ ] Homebrew tap distribution

## License

[MIT](LICENSE)
