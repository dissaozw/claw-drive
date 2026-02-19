#!/usr/bin/env bash
# test/test.sh — Functional tests for Claw Drive
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI="$SCRIPT_DIR/../bin/claw-drive"
TEST_DIR=$(mktemp -d)
SRC_DIR=$(mktemp -d)
export CLAW_DRIVE_DIR="$TEST_DIR"
export CLAW_DRIVE_CONFIG_FILE="$TEST_DIR/.config"

passed=0
failed=0

assert() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "  ✅ $name"
    ((passed++)) || true
  else
    echo "  ❌ $name"
    ((failed++)) || true
  fi
}

assert_output() {
  local name="$1"
  local expected="$2"
  shift 2
  local output
  output=$("$@" 2>&1) || true
  if echo "$output" | grep -qi "$expected"; then
    echo "  ✅ $name"
    ((passed++)) || true
  else
    echo "  ❌ $name (expected '$expected' in output)"
    echo "     Got: $output"
    ((failed++)) || true
  fi
}

assert_jq() {
  local name="$1"
  local file="$2"
  local filter="$3"
  local expected="$4"
  local result
  result=$(jq -r "$filter" "$file" 2>/dev/null) || true
  if [[ "$result" == "$expected" ]]; then
    echo "  ✅ $name"
    ((passed++)) || true
  else
    echo "  ❌ $name (expected '$expected', got '$result')"
    ((failed++)) || true
  fi
}

cleanup() {
  rm -rf "$TEST_DIR" "$SRC_DIR"
}
trap cleanup EXIT

echo "🧪 Claw Drive Tests (dir: $TEST_DIR)"
echo ""

# --- Version & Help ---
echo "Commands:"
assert "version" bash "$CLI" version
assert "help" bash "$CLI" help

# --- Init ---
echo ""
echo "Init:"
assert "init creates directories" bash "$CLI" init
assert "INDEX.jsonl exists" test -f "$TEST_DIR/INDEX.jsonl"
assert ".hashes exists" test -f "$TEST_DIR/.hashes"
assert "documents/ exists" test -d "$TEST_DIR/documents"
assert "finance/ exists" test -d "$TEST_DIR/finance"
assert "identity/ exists" test -d "$TEST_DIR/identity"
assert "misc/ exists" test -d "$TEST_DIR/misc"

# --- Store ---
echo ""
echo "Store:"
echo "test content" > "$SRC_DIR/testfile.txt"
assert "store a file" bash "$CLI" store "$SRC_DIR/testfile.txt" \
  --category documents --desc "Test document for unit tests" --tags "test, document" --source manual
assert "file copied to category" test -f "$TEST_DIR/documents/testfile.txt"

# Verify JSONL structure
assert_jq "index has path" "$TEST_DIR/INDEX.jsonl" '.path' "documents/testfile.txt"
assert_jq "index has desc" "$TEST_DIR/INDEX.jsonl" '.desc' "Test document for unit tests"
assert_jq "index has tags array" "$TEST_DIR/INDEX.jsonl" '.tags[0]' "test"
assert_jq "index has second tag" "$TEST_DIR/INDEX.jsonl" '.tags[1]' "document"
assert_jq "index has source" "$TEST_DIR/INDEX.jsonl" '.source' "manual"
assert_output "hash in ledger" "testfile" cat "$TEST_DIR/.hashes"

# --- Pipe character in description (the bug that killed INDEX.md) ---
echo ""
echo "Pipe in description:"
echo "pipe test" > "$SRC_DIR/pipefile.txt"
assert "store with | in desc" bash "$CLI" store "$SRC_DIR/pipefile.txt" \
  --category documents --desc "File with | pipe | chars" --tags "test" --source manual
# Verify the pipe chars survived
local_desc=$(jq -r 'select(.path=="documents/pipefile.txt") | .desc' "$TEST_DIR/INDEX.jsonl")
if [[ "$local_desc" == "File with | pipe | chars" ]]; then
  echo "  ✅ pipe characters preserved in desc"
  ((passed++)) || true
else
  echo "  ❌ pipe characters NOT preserved (got: $local_desc)"
  ((failed++)) || true
fi

# --- Dedup ---
echo ""
echo "Dedup:"
assert_output "duplicate rejected" "duplicate" bash "$CLI" store "$SRC_DIR/testfile.txt" \
  --category documents --desc "Duplicate" --tags "dupe" --source manual || true

echo "different content" > "$SRC_DIR/testfile2.txt"
assert "different file stores fine" bash "$CLI" store "$SRC_DIR/testfile2.txt" \
  --category finance --desc "Finance doc" --tags "finance, test" --source email

# --- Store with --name ---
echo ""
echo "Store --name:"
echo "ugly content" > "$SRC_DIR/file_17---8c1ee63d.txt"
assert "store with --name" bash "$CLI" store "$SRC_DIR/file_17---8c1ee63d.txt" \
  --category documents --desc "Clean named file" --tags "test" --name "custom-name.txt"
assert "custom name file exists" test -f "$TEST_DIR/documents/custom-name.txt"

# --- New category (agent creates freely) ---
echo ""
echo "Dynamic categories:"
echo "housing doc" > "$SRC_DIR/lease.txt"
assert "store to new category" bash "$CLI" store "$SRC_DIR/lease.txt" \
  --category housing --desc "Lease agreement" --tags "housing, lease" --source manual
assert "new category dir created" test -d "$TEST_DIR/housing"
assert "file in new category" test -f "$TEST_DIR/housing/lease.txt"

# --- Update ---
echo ""
echo "Update:"
assert "update desc" bash "$CLI" update "documents/testfile.txt" \
  --desc "Updated description for test"
local_updated_desc=$(jq -r 'select(.path=="documents/testfile.txt") | .desc' "$TEST_DIR/INDEX.jsonl")
if [[ "$local_updated_desc" == "Updated description for test" ]]; then
  echo "  ✅ desc updated in index"
  ((passed++)) || true
else
  echo "  ❌ desc not updated (got: $local_updated_desc)"
  ((failed++)) || true
fi

assert "update tags" bash "$CLI" update "documents/testfile.txt" \
  --tags "updated, new-tag"
local_updated_tag=$(jq -r 'select(.path=="documents/testfile.txt") | .tags[0]' "$TEST_DIR/INDEX.jsonl")
if [[ "$local_updated_tag" == "updated" ]]; then
  echo "  ✅ tags updated in index"
  ((passed++)) || true
else
  echo "  ❌ tags not updated (got: $local_updated_tag)"
  ((failed++)) || true
fi

assert_output "update nonexistent fails" "Not found" bash "$CLI" update "nonexistent.txt" --desc "nope"

# --- Delete ---
echo ""
echo "Delete:"
assert_output "delete dry run" "Will delete" bash "$CLI" delete "housing/lease.txt"
assert "file still exists after dry run" test -f "$TEST_DIR/housing/lease.txt"

assert "delete with --force" bash "$CLI" delete "housing/lease.txt" --force
assert "file removed" test ! -f "$TEST_DIR/housing/lease.txt"

# Verify index entry removed
local_deleted=$(jq -r 'select(.path=="housing/lease.txt") | .path' "$TEST_DIR/INDEX.jsonl")
if [[ -z "$local_deleted" ]]; then
  echo "  ✅ index entry removed"
  ((passed++)) || true
else
  echo "  ❌ index entry still present"
  ((failed++)) || true
fi

assert_output "delete nonexistent fails" "Not found" bash "$CLI" delete "nonexistent.txt" --force

# --- Verify ---
echo ""
echo "Verify:"
assert_output "verify clean" "All clear" bash "$CLI" verify

# Create an orphan file
echo "orphan" > "$TEST_DIR/documents/orphan.txt"
assert_output "verify catches orphan" "Orphan file" bash "$CLI" verify

# Clean up orphan
rm "$TEST_DIR/documents/orphan.txt"

# --- Status ---
echo ""
echo "Status:"
assert_output "status shows dir" "$TEST_DIR" bash "$CLI" status

# --- Migrate ---
echo ""
echo "Migrate:"
MIGRATE_SRC="$TEST_DIR/migrate-source"
mkdir -p "$MIGRATE_SRC/taxes" "$MIGRATE_SRC/photos"
echo "w2 content" > "$MIGRATE_SRC/taxes/w2-form.pdf"
echo "photo" > "$MIGRATE_SRC/photos/vacation.jpg"
PLAN_FILE="$TEST_DIR/plan.json"

assert "migrate scan" bash "$CLI" migrate scan "$MIGRATE_SRC" "$PLAN_FILE"
assert "plan file created" test -f "$PLAN_FILE"
assert_output "plan has 2 files" "2" python3 -c "import json; print(len(json.load(open('$PLAN_FILE'))['files']))"
assert_output "migrate summary" "Total files: 2" bash "$CLI" migrate summary "$PLAN_FILE"

python3 -c "
import json
plan = json.load(open('$PLAN_FILE'))
for f in plan['files']:
    if 'w2' in f['source_path']:
        f['category'] = 'finance'
        f['name'] = 'w2-form-2025.pdf'
        f['tags'] = 'finance, tax-2025'
        f['description'] = 'W-2 form 2025'
        f['confidence'] = 'high'
    else:
        f['category'] = 'photos'
        f['name'] = 'vacation.jpg'
        f['tags'] = 'photos, vacation'
        f['description'] = 'Vacation photo'
        f['confidence'] = 'medium'
json.dump(plan, open('$PLAN_FILE', 'w'), indent=2)
"

assert "migrate apply dry-run" bash "$CLI" migrate apply "$PLAN_FILE" --dry-run
assert "migrate apply" bash "$CLI" migrate apply "$PLAN_FILE"
assert "migrated file exists" test -f "$TEST_DIR/finance/w2-form-2025.pdf"
assert "migrated photo exists" test -f "$TEST_DIR/photos/vacation.jpg"

# Verify migrated files in JSONL index
local_migrated=$(jq -r 'select(.path=="finance/w2-form-2025.pdf") | .path' "$TEST_DIR/INDEX.jsonl")
if [[ "$local_migrated" == "finance/w2-form-2025.pdf" ]]; then
  echo "  ✅ migrated file in JSONL index"
  ((passed++)) || true
else
  echo "  ❌ migrated file not in index"
  ((failed++)) || true
fi

# --- Results ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: $passed passed, $failed failed"
[[ $failed -eq 0 ]] && echo "✅ All tests passed." || echo "❌ Some tests failed."
exit "$failed"
