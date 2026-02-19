#!/usr/bin/env bash
# lib/dedup.sh — Content-based deduplication for Claw Drive

# Hash a file and return SHA-256
dedup_hash() {
  local file="$1"
  shasum -a 256 "$file" | awk '{print $1}'
}

# Check if a file is a duplicate. Returns 0 if duplicate, 1 if new.
# Prints the existing path if duplicate.
dedup_check() {
  local file="$1"

  if [[ ! -f "$CLAW_DRIVE_HASHES" ]]; then
    return 1
  fi

  local hash
  hash=$(dedup_hash "$file")

  local existing
  existing=$(grep "^$hash " "$CLAW_DRIVE_HASHES" | head -1 | awk '{print $2}')

  if [[ -n "$existing" ]]; then
    echo "$existing"
    return 0
  fi

  return 1
}

# Register a file hash in the dedup ledger
dedup_register() {
  local file="$1"
  local relative_path="$2"

  local hash
  hash=$(dedup_hash "$file")

  echo "$hash  $relative_path" >> "$CLAW_DRIVE_HASHES"
}

# Remove a file's hash from the dedup ledger by relative path
dedup_unregister() {
  local relative_path="$1"

  if [[ ! -f "$CLAW_DRIVE_HASHES" ]]; then
    return 0
  fi

  # Escape path for use in grep/sed (handle special chars)
  local escaped
  escaped=$(printf '%s' "$relative_path" | sed 's/[.[\/*^$]/\\&/g')

  local tmp
  tmp=$(mktemp)
  grep -v "^[^ ]*  ${escaped}$" "$CLAW_DRIVE_HASHES" > "$tmp" || true
  mv "$tmp" "$CLAW_DRIVE_HASHES"
}

# Show dedup stats
dedup_status() {
  local format="${1:-table}"

  if [[ ! -f "$CLAW_DRIVE_HASHES" ]]; then
    echo "No hash ledger found."
    return 0
  fi

  local count
  count=$(wc -l < "$CLAW_DRIVE_HASHES" | xargs)

  if [[ "$format" == "json" ]]; then
    printf '{"tracked_files":%d,"ledger":"%s"}\n' "$count" "$CLAW_DRIVE_HASHES"
  else
    echo "Dedup ledger: $CLAW_DRIVE_HASHES"
    echo "Tracked files: $count"
  fi
}
