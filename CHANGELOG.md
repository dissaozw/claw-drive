# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-02-17

### Added
- Initial release
- CLI with subcommands: `init`, `store`, `search`, `list`, `tags`, `status`, `sync`
- Auto-categorization into 9 file categories
- Tag-based cross-category search via INDEX.md
- SHA-256 content-based deduplication
- Google Drive sync daemon (fswatch + rclone) with launchd integration
- Per-category privacy controls via `.sync-config` exclude list
- JSON output mode (`--json`) for all commands
- OpenClaw skill integration via SKILL.md
