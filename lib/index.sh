#!/usr/bin/env bash
# lib/index.sh — INDEX.md management for Claw Drive

# Search INDEX.md by query string (grep across all columns)
index_search() {
  local query="$1"
  local format="${2:-table}"

  if [[ ! -f "$CLAW_DRIVE_INDEX" ]]; then
    echo "❌ INDEX.md not found at $CLAW_DRIVE_INDEX"
    return 1
  fi

  local results
  results=$(grep -i "$query" "$CLAW_DRIVE_INDEX" | grep -E '^\|' | grep -v '^| Date' | grep -v '^|---')

  if [[ -z "$results" ]]; then
    echo "No files found matching: $query"
    return 0
  fi

  if [[ "$format" == "json" ]]; then
    echo "["
    local first=true
    while IFS='|' read -r _ date path desc tags source _; do
      date=$(echo "$date" | xargs)
      path=$(echo "$path" | xargs)
      desc=$(echo "$desc" | xargs)
      tags=$(echo "$tags" | xargs)
      source=$(echo "$source" | xargs)
      [[ "$first" == "true" ]] || echo ","
      printf '  {"date":"%s","path":"%s","description":"%s","tags":"%s","source":"%s"}' \
        "$date" "$path" "$desc" "$tags" "$source"
      first=false
    done <<< "$results"
    echo ""
    echo "]"
  else
    echo "| Date | Path | Description | Tags | Source |"
    echo "|------|------|-------------|------|--------|"
    echo "$results"
  fi
}

# List all indexed files
index_list() {
  local format="${1:-table}"

  if [[ ! -f "$CLAW_DRIVE_INDEX" ]]; then
    echo "❌ INDEX.md not found at $CLAW_DRIVE_INDEX"
    return 1
  fi

  local results
  results=$(grep -E '^\|' "$CLAW_DRIVE_INDEX" | grep -v '^| Date' | grep -v '^|---')

  if [[ -z "$results" ]]; then
    echo "No files indexed."
    return 0
  fi

  local count
  count=$(echo "$results" | wc -l | xargs)

  if [[ "$format" == "json" ]]; then
    echo "["
    local first=true
    while IFS='|' read -r _ date path desc tags source _; do
      date=$(echo "$date" | xargs)
      path=$(echo "$path" | xargs)
      desc=$(echo "$desc" | xargs)
      tags=$(echo "$tags" | xargs)
      source=$(echo "$source" | xargs)
      [[ "$first" == "true" ]] || echo ","
      printf '  {"date":"%s","path":"%s","description":"%s","tags":"%s","source":"%s"}' \
        "$date" "$path" "$desc" "$tags" "$source"
      first=false
    done <<< "$results"
    echo ""
    echo "]"
  else
    echo "| Date | Path | Description | Tags | Source |"
    echo "|------|------|-------------|------|--------|"
    echo "$results"
    echo ""
    echo "$count file(s) indexed."
  fi
}

# List all unique tags
index_tags() {
  local format="${1:-table}"

  if [[ ! -f "$CLAW_DRIVE_INDEX" ]]; then
    echo "❌ INDEX.md not found at $CLAW_DRIVE_INDEX"
    return 1
  fi

  local tags
  tags=$(grep -E '^\|' "$CLAW_DRIVE_INDEX" | grep -v '^| Date' | grep -v '^|---' | \
    awk -F'|' '{print $5}' | tr ',' '\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | \
    grep -v '^$' | sort | uniq -c | sort -rn)

  if [[ -z "$tags" ]]; then
    echo "No tags found."
    return 0
  fi

  if [[ "$format" == "json" ]]; then
    echo "["
    local first=true
    while read -r count tag; do
      [[ "$first" == "true" ]] || echo ","
      printf '  {"tag":"%s","count":%d}' "$tag" "$count"
      first=false
    done <<< "$tags"
    echo ""
    echo "]"
  else
    echo "Tags (by usage):"
    while read -r count tag; do
      printf "  %-20s %d file(s)\n" "$tag" "$count"
    done <<< "$tags"
  fi
}
