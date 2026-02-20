#!/usr/bin/env bash
# lib/index.sh — INDEX.jsonl management for Claw Drive
#
# INDEX.jsonl is a structured JSONL file — one JSON object per line.
# Agents read it directly for search/list/tag operations.
# This library handles atomic write operations (add, update, delete).

# Append a new entry to the index
index_add() {
  local date="$1" path="$2" desc="$3" tags="$4" source="$5"

  # Convert comma-separated tags to JSON array
  local tags_json
  tags_json=$(printf '%s' "$tags" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$";""))')

  jq -cn \
    --arg date "$date" \
    --arg path "$path" \
    --arg desc "$desc" \
    --argjson tags "$tags_json" \
    --arg source "$source" \
    '{date:$date, path:$path, desc:$desc, tags:$tags, source:$source}' \
    >> "$CLAW_DRIVE_INDEX"
}

# Remove an entry by path (exact match)
index_remove() {
  local target_path="$1"
  local tmp
  tmp=$(mktemp)

  jq -c --arg path "$target_path" 'select(.path != $path)' "$CLAW_DRIVE_INDEX" > "$tmp"
  mv "$tmp" "$CLAW_DRIVE_INDEX"
}

# Update fields on an entry by path (exact match)
# Usage: index_update <path> [--desc <desc>] [--tags <tags>]
index_update() {
  local target_path="$1"
  shift

  local new_desc="" new_tags=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --desc|-d) new_desc="$2"; shift 2 ;;
      --tags|-t) new_tags="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  local tmp
  tmp=$(mktemp)

  local jq_filter='if .path == $path then'
  local jq_args
  jq_args=(--arg path "$target_path")

  if [[ -n "$new_desc" ]]; then
    jq_filter="$jq_filter .desc = \$desc |"
    jq_args+=(--arg desc "$new_desc")
  fi

  if [[ -n "$new_tags" ]]; then
    local tags_json
    tags_json=$(printf '%s' "$new_tags" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$";""))')
    jq_filter="$jq_filter .tags = \$tags |"
    jq_args+=(--argjson tags "$tags_json")
  fi

  # Remove trailing pipe if present
  jq_filter="${jq_filter% |}"
  jq_filter="$jq_filter else . end"

  jq -c "${jq_args[@]}" "$jq_filter" "$CLAW_DRIVE_INDEX" > "$tmp"
  mv "$tmp" "$CLAW_DRIVE_INDEX"
}

# Check if a path exists in the index
index_has() {
  local target_path="$1"
  jq -e --arg p "$target_path" 'select(.path == $p)' "$CLAW_DRIVE_INDEX" > /dev/null 2>&1
}

# Dedup: remove hash entry for a path (exact match, regex-safe)
dedup_unregister() {
  local target_path="$1"

  if [[ ! -f "$CLAW_DRIVE_HASHES" ]]; then
    return 0
  fi

  local tmp
  tmp=$(mktemp)
  # Use shell parameter expansion to extract path from "hash  path" format,
  # avoiding unescaped grep which breaks on regex special chars (., (, ), etc.)
  while IFS= read -r line || [[ -n "$line" ]]; do
    local line_path="${line#*  }"
    [[ "$line_path" != "$target_path" ]] && printf '%s\n' "$line"
  done < "$CLAW_DRIVE_HASHES" > "$tmp"
  mv "$tmp" "$CLAW_DRIVE_HASHES"
}
