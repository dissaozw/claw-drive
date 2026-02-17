#!/usr/bin/env bash
# test/test.sh — Basic functional tests for Claw Drive
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI="$SCRIPT_DIR/../bin/claw-drive"
TEST_DIR=$(mktemp -d)
export CLAW_DRIVE_DIR="$TEST_DIR"

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

cleanup() {
  rm -rf "$TEST_DIR"
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
assert "INDEX.md exists" test -f "$TEST_DIR/INDEX.md"
assert ".hashes exists" test -f "$TEST_DIR/.hashes"
assert "documents/ exists" test -d "$TEST_DIR/documents"
assert "finance/ exists" test -d "$TEST_DIR/finance"
assert "identity/ exists" test -d "$TEST_DIR/identity"
assert "misc/ exists" test -d "$TEST_DIR/misc"

# --- Store ---
echo ""
echo "Store:"
echo "test content" > "$TEST_DIR/testfile.txt"
assert "store a file" bash "$CLI" store "$TEST_DIR/testfile.txt" \
  --category documents --desc "Test document" --tags "test, document" --source manual
assert "file copied to category" test -f "$TEST_DIR/documents/testfile.txt"
assert_output "file in INDEX.md" "test document" grep -i "testfile" "$TEST_DIR/INDEX.md"
assert_output "tags in INDEX.md" "test, document" grep "testfile" "$TEST_DIR/INDEX.md"
assert_output "hash in ledger" "testfile" cat "$TEST_DIR/.hashes"

# --- Dedup ---
echo ""
echo "Dedup:"
assert_output "duplicate rejected" "duplicate" bash "$CLI" store "$TEST_DIR/testfile.txt" \
  --category documents --desc "Duplicate" --tags "dupe" --source manual || true

# Store a different file (should succeed)
echo "different content" > "$TEST_DIR/testfile2.txt"
assert "different file stores fine" bash "$CLI" store "$TEST_DIR/testfile2.txt" \
  --category finance --desc "Finance doc" --tags "finance, test" --source email

# --- Search ---
echo ""
echo "Search:"
assert_output "search by description" "testfile" bash "$CLI" search "test document"
assert_output "search by tag" "testfile" bash "$CLI" search "document"
assert_output "search no results" "No files found" bash "$CLI" search "nonexistent"

# --- List ---
echo ""
echo "List:"
assert_output "list shows files" "testfile" bash "$CLI" list
assert_output "list json valid" "date" bash "$CLI" list --json

# --- Tags ---
echo ""
echo "Tags:"
assert_output "tags shows test" "test" bash "$CLI" tags
assert_output "tags json valid" "tag" bash "$CLI" tags --json

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

# Fill in the plan for apply test
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
assert_output "migrated file indexed" "w2-form-2025" cat "$TEST_DIR/INDEX.md"

# --- Results ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: $passed passed, $failed failed"
[[ $failed -eq 0 ]] && echo "✅ All tests passed." || echo "❌ Some tests failed."
exit "$failed"
