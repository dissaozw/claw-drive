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

# --- Results ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: $passed passed, $failed failed"
[[ $failed -eq 0 ]] && echo "✅ All tests passed." || echo "❌ Some tests failed."
exit "$failed"
