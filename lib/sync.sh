#!/usr/bin/env bash
# lib/sync.sh — Google Drive sync daemon for Claw Drive

SYNC_DEBOUNCE_SEC=3
SYNC_AUTH_TIMEOUT=120  # Kill ngrok after 2 minutes regardless

# Authenticate with Google Drive via rclone + ngrok tunnel
sync_auth() {
  echo "🔐 Claw Drive — Google Drive Authorization"
  echo ""

  # Check dependencies
  if ! command -v rclone &>/dev/null; then
    echo "❌ rclone not found. Install: brew install rclone"
    return 1
  fi
  if ! command -v ngrok &>/dev/null; then
    echo "❌ ngrok not found. Install: brew install ngrok"
    return 1
  fi

  # Check if remote already exists
  if rclone listremotes 2>/dev/null | grep -q "^gdrive:$"; then
    echo "⚠️  rclone remote 'gdrive' already exists."
    echo "   To re-authorize, run: rclone config delete gdrive"
    echo "   Then run this command again."
    return 1
  fi

  local ngrok_pid=""
  local rclone_pid=""
  local ngrok_log
  ngrok_log=$(mktemp)

  # Cleanup function — always kill ngrok and rclone
  _sync_auth_cleanup() {
    [[ -n "$ngrok_pid" ]] && kill "$ngrok_pid" 2>/dev/null && wait "$ngrok_pid" 2>/dev/null
    [[ -n "$rclone_pid" ]] && kill "$rclone_pid" 2>/dev/null && wait "$rclone_pid" 2>/dev/null
    rm -f "$ngrok_log"
    echo ""
    echo "🔒 Tunnel closed."
  }
  trap _sync_auth_cleanup EXIT

  # Start ngrok tunnel to rclone's OAuth callback port
  echo "🔗 Starting secure tunnel..."
  ngrok http 53682 --log=stdout --log-format=json > "$ngrok_log" 2>&1 &
  ngrok_pid=$!

  # Wait for ngrok to provide the public URL (max 10 seconds)
  local ngrok_url=""
  local waited=0
  while [[ -z "$ngrok_url" && $waited -lt 10 ]]; do
    sleep 1
    ((waited++)) || true
    ngrok_url=$(grep -o '"url":"https://[^"]*"' "$ngrok_log" 2>/dev/null | head -1 | sed 's/"url":"//;s/"//' || true)
  done

  if [[ -z "$ngrok_url" ]]; then
    echo "❌ Failed to start ngrok tunnel."
    return 1
  fi

  echo "✅ Tunnel ready: $ngrok_url"
  echo ""

  # Start safety timeout — kill ngrok after SYNC_AUTH_TIMEOUT seconds
  (
    sleep "$SYNC_AUTH_TIMEOUT"
    kill "$ngrok_pid" 2>/dev/null
    echo ""
    echo "⏰ Auth timeout (${SYNC_AUTH_TIMEOUT}s). Tunnel killed for safety."
  ) &
  local timeout_pid=$!

  # Start rclone authorize with the ngrok redirect
  echo "🔑 Starting Google Drive authorization..."
  echo "   Paste this URL in your browser to authorize:"
  echo ""

  # Run rclone authorize and capture output
  local rclone_out
  rclone_out=$(mktemp)
  RCLONE_OAUTH_CALLBACK_URL="$ngrok_url" rclone authorize "drive" > "$rclone_out" 2>&1 &
  rclone_pid=$!

  # Wait for rclone to print the auth URL (max 15 seconds)
  local auth_url=""
  waited=0
  while [[ -z "$auth_url" && $waited -lt 15 ]]; do
    sleep 1
    ((waited++)) || true
    auth_url=$(grep -o 'http[s]*://accounts.google.com[^ ]*' "$rclone_out" 2>/dev/null | head -1 || true)
  done

  if [[ -n "$auth_url" ]]; then
    echo "   $auth_url"
  else
    echo "   (waiting for rclone to generate auth URL...)"
    echo "   Check rclone output: $rclone_out"
  fi

  echo ""
  echo "⏳ Waiting for authorization (timeout: ${SYNC_AUTH_TIMEOUT}s)..."

  # Wait for rclone to finish (user completes auth)
  wait "$rclone_pid" 2>/dev/null
  local rclone_exit=$?
  rclone_pid=""

  # Kill timeout watcher
  kill "$timeout_pid" 2>/dev/null || true

  # Kill ngrok immediately
  if [[ -n "$ngrok_pid" ]]; then
    kill "$ngrok_pid" 2>/dev/null || true
    wait "$ngrok_pid" 2>/dev/null || true
    ngrok_pid=""
  fi

  echo "🔒 Tunnel closed."

  if [[ $rclone_exit -ne 0 ]]; then
    echo "❌ Authorization failed or timed out."
    cat "$rclone_out"
    rm -f "$rclone_out"
    return 1
  fi

  # Extract token from rclone output
  local token
  token=$(sed -n '/^{/,/^}/p' "$rclone_out" | head -20)
  rm -f "$rclone_out"

  if [[ -z "$token" ]]; then
    echo "❌ Could not extract token from rclone output."
    return 1
  fi

  echo "✅ Authorization successful!"
  echo ""

  # Configure rclone remote with the token
  rclone config create gdrive drive config_is_local=false config_token="$token" > /dev/null 2>&1

  echo "✅ rclone remote 'gdrive' configured."
  echo ""

  # Create default .sync-config if it doesn't exist
  if [[ ! -f "$CLAW_DRIVE_SYNC_CONFIG" ]]; then
    cat > "$CLAW_DRIVE_SYNC_CONFIG" <<EOF
backend: google-drive
remote: gdrive:claw-drive
exclude:
  - identity/
  - .hashes
EOF
    echo "✅ Created $CLAW_DRIVE_SYNC_CONFIG"
  fi

  echo ""
  echo "🎉 Google Drive sync is ready!"
  echo "   Run: claw-drive sync start"

  # Reset trap
  trap - EXIT
}

# Check sync prerequisites
sync_setup() {
  echo "🗄️  Claw Drive Sync Setup"
  echo ""

  local ok=true

  if command -v rclone &>/dev/null; then
    echo "✅ rclone installed ($(rclone version | head -1))"
  else
    echo "❌ rclone not found. Install: brew install rclone"
    ok=false
  fi

  if command -v fswatch &>/dev/null; then
    echo "✅ fswatch installed"
  else
    echo "❌ fswatch not found. Install: brew install fswatch"
    ok=false
  fi

  if [[ -d "$CLAW_DRIVE_DIR" ]]; then
    echo "✅ Drive directory: $CLAW_DRIVE_DIR"
  else
    echo "❌ Drive directory not found: $CLAW_DRIVE_DIR"
    ok=false
  fi

  local remote
  remote=$(sync_config_get "remote")
  if [[ -z "$remote" ]]; then
    echo ""
    echo "⚠️  No .sync-config found. Create $CLAW_DRIVE_SYNC_CONFIG:"
    echo ""
    echo "  backend: google-drive"
    echo "  remote: gdrive:claw-drive"
    echo "  exclude:"
    echo "    - identity/"
    echo "    - .hashes"
    return 1
  fi

  local remote_name="${remote%%:*}"
  if rclone listremotes | grep -q "^${remote_name}:$"; then
    echo "✅ rclone remote '$remote_name' configured"
  else
    echo "❌ rclone remote '$remote_name' not found. Run: rclone config"
    ok=false
  fi

  [[ "$ok" == "true" ]] || return 1

  echo ""
  echo "✅ Ready! Run: claw-drive sync start"
}

# One-shot sync
sync_push() {
  local remote
  remote=$(sync_config_get "remote")
  if [[ -z "$remote" ]]; then
    echo "❌ No remote configured. Run: claw-drive sync setup"
    return 1
  fi

  local exclude_args
  exclude_args=$(sync_build_exclude_args)

  echo "📤 Syncing $CLAW_DRIVE_DIR → $remote ..."
  # shellcheck disable=SC2086
  rclone sync "$CLAW_DRIVE_DIR" "$remote" $exclude_args --verbose 2>&1

  date -u +"%Y-%m-%dT%H:%M:%SZ" > "$CLAW_DRIVE_SYNC_STATE"
  echo "✅ Sync complete."
}

# Internal: fswatch loop (called by launchd)
sync_watch_loop() {
  local remote
  remote=$(sync_config_get "remote")
  if [[ -z "$remote" ]]; then
    echo "❌ No remote configured." >&2
    return 1
  fi

  local exclude_args
  exclude_args=$(sync_build_exclude_args)

  echo "👀 Watching $CLAW_DRIVE_DIR for changes (debounce: ${SYNC_DEBOUNCE_SEC}s)..."
  echo "📡 Remote: $remote"

  fswatch -o -l "$SYNC_DEBOUNCE_SEC" \
    --exclude '\.sync-state$' \
    --exclude '\.sync-config$' \
    --exclude '\.DS_Store$' \
    "$CLAW_DRIVE_DIR" | while read -r _count; do
    echo "[$(date '+%H:%M:%S')] Change detected, syncing..."
    # shellcheck disable=SC2086
    if rclone sync "$CLAW_DRIVE_DIR" "$remote" $exclude_args 2>&1; then
      date -u +"%Y-%m-%dT%H:%M:%SZ" > "$CLAW_DRIVE_SYNC_STATE"
      echo "[$(date '+%H:%M:%S')] ✅ Sync complete."
    else
      echo "[$(date '+%H:%M:%S')] ❌ Sync failed." >&2
    fi
  done
}

# Start the sync daemon via launchd
sync_start() {
  if launchctl list 2>/dev/null | grep -q "$CLAW_DRIVE_PLIST_NAME"; then
    echo "⚠️  Already running. Use 'claw-drive sync stop' first."
    return 1
  fi

  mkdir -p "$CLAW_DRIVE_LOG_DIR"

  local script_path
  script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bin/claw-drive"

  cat > "$CLAW_DRIVE_PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$CLAW_DRIVE_PLIST_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>$script_path</string>
        <string>sync</string>
        <string>_watch</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
        <key>CLAW_DRIVE_DIR</key>
        <string>$CLAW_DRIVE_DIR</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$CLAW_DRIVE_LOG_DIR/sync.log</string>
    <key>StandardErrorPath</key>
    <string>$CLAW_DRIVE_LOG_DIR/sync.err</string>
</dict>
</plist>
EOF

  launchctl load "$CLAW_DRIVE_PLIST_PATH"
  echo "✅ Sync daemon started."
  echo "   Logs: $CLAW_DRIVE_LOG_DIR/sync.log"
}

# Stop the sync daemon
sync_stop() {
  if [[ -f "$CLAW_DRIVE_PLIST_PATH" ]]; then
    launchctl unload "$CLAW_DRIVE_PLIST_PATH" 2>/dev/null || true
    rm -f "$CLAW_DRIVE_PLIST_PATH"
    echo "✅ Sync daemon stopped."
  else
    echo "⚠️  Not running."
  fi
}

# Show sync status
sync_status() {
  local format="${1:-table}"

  local running="false"
  if launchctl list 2>/dev/null | grep -q "$CLAW_DRIVE_PLIST_NAME"; then
    running="true"
  fi

  local remote
  remote=$(sync_config_get "remote")

  local last_sync="never"
  if [[ -f "$CLAW_DRIVE_SYNC_STATE" ]]; then
    last_sync=$(cat "$CLAW_DRIVE_SYNC_STATE")
  fi

  if [[ "$format" == "json" ]]; then
    printf '{"daemon_running":%s,"remote":"%s","last_sync":"%s"}\n' \
      "$running" "${remote:-null}" "$last_sync"
  else
    echo "🗄️  Claw Drive Sync Status"
    echo ""
    if [[ "$running" == "true" ]]; then
      echo "🟢 Daemon: running"
    else
      echo "🔴 Daemon: stopped"
    fi
    echo "📡 Remote: ${remote:-not configured}"
    echo "🕐 Last sync: $last_sync"

    local excludes
    excludes=$(sync_config_excludes)
    if [[ -n "$excludes" ]]; then
      echo "🚫 Excludes:"
      while IFS= read -r e; do
        echo "   - $e"
      done <<< "$excludes"
    fi
  fi
}
