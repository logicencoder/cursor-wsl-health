#!/usr/bin/env bash
# Cursor + WSL health — interactive menu. No arguments needed.
# Repo: https://github.com/logicencoder/cursor-wsl-health
# Run: ~/cursor_wsl_health.sh  (symlink to this file)
#
# Keeps ONE long agent chat: use "Reload Window" after clean/reset (not New Chat).
# All user-facing text in this script is English (see ~/.cursor/rules/cursor-wsl-health.mdc).

HOME_LOJZO="${HOME:-/home/lojzo}"
WIN_USER="${WIN_USER:-Lojzek}"
WIN_LOG_ROOT="/mnt/c/Users/${WIN_USER}/AppData/Roaming/Cursor/logs"
AGENT_ROOT="${HOME_LOJZO}/.cursor/projects"
PROJECT_ROOT="${CURSOR_HEALTH_PROJECT:-${HOME_LOJZO}/cex_dex_arb_app}"
PROJECT_LABEL="${CURSOR_HEALTH_PROJECT_LABEL:-$(basename "$PROJECT_ROOT")}"
STATE_FILE="${CURSOR_HEALTH_CHECKPOINT:-${PROJECT_ROOT}/.cursor_session_checkpoint.md}"
PROJECT_REPORTS="${CURSOR_HEALTH_REPORTS:-${PROJECT_ROOT}/reports}"
PROJECT_SCRIPTS="${CURSOR_HEALTH_SCRIPTS:-${PROJECT_ROOT}/scripts}"
TOOL_SIZE_MB=10
LOG_AGE_DAYS=7

# --- colors ($'...' so \033 is a real escape, not literal text) ---
use_color() { [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; }

if use_color; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_RED=$'\033[31m'
  C_GRN=$'\033[32m'
  C_YLW=$'\033[33m'
  C_CYN=$'\033[36m'
else
  C_RESET= C_BOLD= C_DIM= C_RED= C_GRN= C_YLW= C_CYN=
fi

hr() { printf '%s\n' "────────────────────────────────────────────────────────"; }
title() { printf '\n%s%s%s\n' "$C_BOLD" "$*" "$C_RESET"; hr; }
ok() { printf '  %s✓%s %s\n' "$C_GRN" "$C_RESET" "$*"; }
warn() { printf '  %s!%s %s\n' "$C_YLW" "$C_RESET" "$*"; }
bad() { printf '  %s✗%s %s\n' "$C_RED" "$C_RESET" "$*"; }
info() { printf '  %s·%s %s\n' "$C_DIM" "$C_RESET" "$*"; }

human_bytes() {
  local b="${1:-0}"
  if command -v numfmt >/dev/null 2>&1; then
    numfmt --to=iec --suffix=B "$b" 2>/dev/null || echo "${b} B"
  elif (( b >= 1073741824 )); then
    printf '%.1f GB' "$(awk "BEGIN {print $b/1073741824}")"
  elif (( b >= 1048576 )); then
    printf '%.1f MB' "$(awk "BEGIN {print $b/1048576}")"
  elif (( b >= 1024 )); then
    printf '%.1f KB' "$(awk "BEGIN {print $b/1024}")"
  else
    printf '%d B' "$b"
  fi
}

dir_size_bytes() {
  local d="$1"
  [[ -d "$d" ]] || { echo 0; return; }
  du -sb "$d" 2>/dev/null | awk '{print $1}' || echo 0
}

count_oom_events() {
  local n=0
  if [[ -d "$WIN_LOG_ROOT" ]]; then
    n=$(grep -rh '"reason":"oom"' "$WIN_LOG_ROOT"/*/cursor-sentry-events.log 2>/dev/null | wc -l || true)
  fi
  echo "${n// /}"
}

cursor_server_pid() {
  pgrep -f 'cursor-server.*server-main' 2>/dev/null | head -1 || true
}

cursor_server_uptime_human() {
  local pid
  pid=$(cursor_server_pid)
  [[ -n "$pid" ]] || { echo "not running"; return; }
  ps -o etime= -p "$pid" 2>/dev/null | xargs || echo "?"
}

cursor_server_rss_mb() {
  local pid
  pid=$(cursor_server_pid)
  [[ -n "$pid" ]] || { echo "0"; return; }
  ps -o rss= -p "$pid" 2>/dev/null | awk '{printf "%.0f", $1/1024}' || echo "0"
}

agent_tools_stats() {
  LARGE_COUNT=0
  LARGE_BYTES=0
  TOTAL_TXT=0
  TOTAL_TXT_BYTES=0
  if [[ -d "$AGENT_ROOT" ]]; then
    while IFS= read -r line; do
      local sz path
      sz=$(echo "$line" | awk '{print $1}')
      path=$(echo "$line" | cut -d' ' -f2-)
      TOTAL_TXT=$((TOTAL_TXT + 1))
      TOTAL_TXT_BYTES=$((TOTAL_TXT_BYTES + sz))
      if (( sz > TOOL_SIZE_MB * 1024 * 1024 )); then
        LARGE_COUNT=$((LARGE_COUNT + 1))
        LARGE_BYTES=$((LARGE_BYTES + sz))
      fi
    done < <(find "$AGENT_ROOT" -path '*/agent-tools/*.txt' -printf '%s %p\n' 2>/dev/null)
  fi
}

transcript_top_stats() {
  TRANSCRIPT_TOP=""
  if [[ -d "$AGENT_ROOT" ]]; then
    TRANSCRIPT_TOP=$(find "$AGENT_ROOT" -path '*/agent-transcripts/*/*.jsonl' -printf '%s %p\n' 2>/dev/null \
      | sort -rn | head -3)
  fi
}

print_dashboard() {
  agent_tools_stats
  local oom_count mem_avail cs_uptime cs_mb fw eh
  oom_count=$(count_oom_events)
  mem_avail=$(free -b 2>/dev/null | awk '/^Mem:/ {print $7}' || echo 0)
  cs_uptime=$(cursor_server_uptime_human)
  cs_mb=$(cursor_server_rss_mb)
  eh=$(pgrep -cf 'type=extensionHost' 2>/dev/null || echo 0)
  fw=$(pgrep -cf 'type=fileWatcher' 2>/dev/null || echo 0)

  title "CURSOR + WSL HEALTH — $(date '+%Y-%m-%d %H:%M:%S')"

  printf '%s%s%s\n' "$C_CYN" "Memory (WSL)" "$C_RESET"
  free -h | awk 'NR<=2 {print "  "$0}'
  info "Available: $(human_bytes "$mem_avail")"

  printf '\n%s%s%s\n' "$C_CYN" "Cursor processes" "$C_RESET"
  if [[ -n "$(cursor_server_pid)" ]]; then
    info "cursor-server uptime: ${cs_uptime}  |  RSS: ~${cs_mb} MB"
    if [[ "$cs_uptime" =~ ^[0-9]+-[0-9]+: ]]; then
      warn "Server running for days — use menu [5] Soft reset"
    fi
  else
    warn "cursor-server is not running"
  fi
  info "extensionHost: ${eh}  |  fileWatcher: ${fw}"
  (( fw > 3 )) && warn "Many fileWatchers — close extra Cursor windows"

  printf '\n%s%s%s\n' "$C_CYN" "Agent cache (causes Windows OOM)" "$C_RESET"
  info "agent-tools .txt files: ${TOTAL_TXT}  |  total: $(human_bytes "$TOTAL_TXT_BYTES")"
  if (( LARGE_COUNT > 0 )); then
    bad "Large files (>${TOOL_SIZE_MB} MB): ${LARGE_COUNT}  |  $(human_bytes "$LARGE_BYTES") eligible for deletion"
    find "$AGENT_ROOT" -path '*/agent-tools/*.txt' -size +"${TOOL_SIZE_MB}"M -printf '    %s %p\n' 2>/dev/null \
      | sort -rn | head -5 \
      | while read -r sz path; do
          info "$(human_bytes "$sz")  $(basename "$path")"
        done
  else
    ok "No oversized agent-tools (>${TOOL_SIZE_MB} MB)"
  fi

  transcript_top_stats
  if [[ -n "$TRANSCRIPT_TOP" ]]; then
    info "Largest chat transcripts:"
    echo "$TRANSCRIPT_TOP" | while read -r sz path; do
      info "$(human_bytes "$sz")  $(echo "$path" | sed 's|.*/projects/||')"
    done
    warn "Long chat = large transcript — clean won't help; Reload Window will"
  fi

  printf '\n%s%s%s\n' "$C_CYN" "Windows Cursor OOM (renderer crash)" "$C_RESET"
  if (( oom_count > 0 )); then
    bad "Total OOM crashes in logs: ${oom_count}"
    grep -rh '"reason":"oom"' "$WIN_LOG_ROOT"/*/cursor-sentry-events.log 2>/dev/null \
      | sed -n 's/.*\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\).*/\1/p' \
      | tail -3 | while read -r t; do info "latest: $t"; done
  else
    ok "No OOM in Windows logs (or /mnt/c unavailable)"
  fi

  printf '\n%s%s%s\n' "$C_CYN" "Project ${PROJECT_LABEL} (tests — NEVER deleted)" "$C_RESET"
  if [[ -d "$PROJECT_REPORTS" ]]; then
    local rc
    rc=$(find "$PROJECT_REPORTS" -maxdepth 1 -type f 2>/dev/null | wc -l)
    ok "reports/: ${rc} files  ($(human_bytes "$(dir_size_bytes "$PROJECT_REPORTS")"))"
  fi
  if [[ -d "$PROJECT_SCRIPTS" ]]; then
    local sc
    sc=$(find "$PROJECT_SCRIPTS" -maxdepth 1 \( -name '*empirical*' -o -name '*playwright*' -o -name 'alva_*' \) -type f 2>/dev/null | wc -l)
    ok "scripts/ test files: ${sc}"
  fi

  printf '\n%s%s%s\n' "$C_CYN" "Session checkpoint" "$C_RESET"
  if [[ -f "$STATE_FILE" ]]; then
    ok "$(basename "$STATE_FILE") — $(wc -l <"$STATE_FILE") lines"
    info "@-mention after crash/reload — no new chat needed"
  else
    warn "Missing checkpoint — menu [8] creates a template"
  fi

  hr
  info "After clean/reset: Ctrl+Shift+P → Developer: Reload Window (SAME chat)"
  hr
}

pause_enter() {
  printf '\n%sPress Enter...%s' "$C_DIM" "$C_RESET"
  read -r _
}

do_clean_agent_tools() {
  title "Cleaning large agent-tools (>${TOOL_SIZE_MB} MB)"
  agent_tools_stats
  info "Before: ${LARGE_COUNT} large files, $(human_bytes "$LARGE_BYTES")"

  local freed=0 removed=0
  if [[ -d "$AGENT_ROOT" ]]; then
    while IFS= read -r -d '' f; do
      local sz base
      sz=$(stat -c%s "$f" 2>/dev/null || echo 0)
      base=$(basename "$f")
      bad "deleting $(human_bytes "$sz")  ${base}"
      rm -f "$f"
      freed=$((freed + sz))
      removed=$((removed + 1))
    done < <(find "$AGENT_ROOT" -path '*/agent-tools/*.txt' -size +"${TOOL_SIZE_MB}"M -print0 2>/dev/null)
  fi

  if (( removed > 0 )); then
    ok "Removed files: ${removed}"
    ok "Freed: $(human_bytes "$freed")"
  else
    info "Nothing to delete — already clean"
  fi
  warn "Now: Reload Window in Cursor (same chat)"
}

do_clean_win_logs() {
  title "Cleaning old Windows Cursor logs (>${LOG_AGE_DAYS} days)"
  if [[ ! -d "$WIN_LOG_ROOT" ]]; then
    bad "Unavailable: $WIN_LOG_ROOT"
    return
  fi
  local removed=0 freed=0
  while IFS= read -r d; do
    local sz
    sz=$(dir_size_bytes "$d")
    bad "deleting $(basename "$d")  ($(human_bytes "$sz"))"
    rm -rf "$d"
    removed=$((removed + 1))
    freed=$((freed + sz))
  done < <(find "$WIN_LOG_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +"${LOG_AGE_DAYS}" 2>/dev/null)

  if (( removed > 0 )); then
    ok "Deleted session folders: ${removed}"
    ok "Freed: ~$(human_bytes "$freed")"
  else
    info "No old logs to delete"
  fi
}

do_drop_caches() {
  title "Linux drop_caches (safe)"
  if echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1; then
    ok "Page cache cleared"
  else
    warn "Skipped (needs sudo or not root)"
  fi
}

do_clean_all() {
  do_clean_agent_tools
  echo ""
  do_clean_win_logs
  echo ""
  do_drop_caches
  title "DONE — clean all"
  ok "Project reports/ and scripts/ were NOT touched"
  warn "Ctrl+Shift+P → Developer: Reload Window"
}

do_soft_reset() {
  title "Soft reset cursor-server (WSL)"
  local pid uptime
  pid=$(cursor_server_pid)
  uptime=$(cursor_server_uptime_human)
  if [[ -z "$pid" ]]; then
    info "cursor-server is not running — Reload Window will restart it"
    return
  fi
  info "Stopping PID ${pid} (uptime: ${uptime})"
  kill "$pid" 2>/dev/null || true
  sleep 2
  pkill -f 'cursor-server.*bootstrap-fork' 2>/dev/null || true
  sleep 1
  if pgrep -f 'cursor-server.*server-main' >/dev/null 2>&1; then
    bad "Server still running — fully quit Cursor once and try again"
    return 1
  fi
  ok "cursor-server stopped"
  warn "Now: Reload Window — chat stays, server reboots fresh"
}

do_tuneup() {
  title "FULL TUNE-UP (clean + soft reset)"
  do_clean_all
  echo ""
  do_soft_reset || true
}

do_oom_report() {
  title "OOM crash report (Windows renderer)"
  if [[ ! -d "$WIN_LOG_ROOT" ]]; then
    bad "Logs unavailable under $WIN_LOG_ROOT"
    return
  fi
  local total
  total=$(count_oom_events)
  bad "Total OOM events: ${total}"
  echo ""
  info "Last 15 crashes:"
  grep -rh '"reason":"oom"' "$WIN_LOG_ROOT"/*/cursor-sentry-events.log 2>/dev/null \
    | sed -n 's/.*\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\).*/\1/p' \
    | tail -15 | nl -w2 -s'. '
  echo ""
  warn "Cause: Electron renderer OOM — not WSL, not your code"
  info "Fix: menu [3] or [4], then Reload Window; one chat is fine"
}

do_checkpoint_show() {
  title "Session checkpoint"
  if [[ ! -f "$STATE_FILE" ]]; then
    warn "File does not exist — use menu [8]"
    return
  fi
  info "$STATE_FILE"
  echo ""
  cat "$STATE_FILE"
}

do_checkpoint_create() {
  title "Create checkpoint template"
  if [[ -f "$STATE_FILE" ]]; then
    warn "Already exists — not overwriting"
    info "$STATE_FILE"
    return
  fi
  mkdir -p "$(dirname "$STATE_FILE")"
  cat >"$STATE_FILE" <<'EOF'
# Cursor session checkpoint (edit by hand or ask agent to update)

## Current goal


## Done (do not redo)


## Git
- Branch:
- Last commit:

## Running services
- Dashboard :
- Scanner :

## Known issues / next step


EOF
  ok "Created: $STATE_FILE"
}

do_project_inventory() {
  title "${PROJECT_LABEL} — tests and reports (safe, in repo)"
  if [[ -d "$PROJECT_REPORTS" ]]; then
    info "reports/ ($(find "$PROJECT_REPORTS" -maxdepth 1 -type f | wc -l) files):"
    ls -lh "$PROJECT_REPORTS" 2>/dev/null | tail -n +2 | awk '{printf "    %s  %s\n", $5, $9}'
  fi
  echo ""
  if [[ -d "$PROJECT_SCRIPTS" ]]; then
    info "scripts/ (empirical + playwright):"
    find "$PROJECT_SCRIPTS" -maxdepth 1 -type f \( -name '*empirical*' -o -name '*playwright*' -o -name 'alva_*' \) \
      -printf '    %s %f\n' 2>/dev/null | sort -rn | head -12 \
      | while read -r sz name; do info "$(human_bytes "$sz")  $name"; done
  fi
  ok "Clean never deletes these files"
}

do_tips() {
  title "One chat — keep context"
  cat <<'EOF'
  1. You do NOT need a new chat because of memory pressure.
  2. After clean/reset: Ctrl+Shift+P → "Developer: Reload Window"
  3. Checkpoint: .cursor_session_checkpoint.md — @-mention after reload
  4. Close extra Cursor windows (often 6+ window* processes)
  5. Disable Browser MCP when you are not using Playwright
  6. Run menu [5] occasionally if cursor-server has been up for days
  7. Long chat transcripts grow — that is OK; clean only removes tool dumps
EOF
}

show_menu() {
  printf '\n%s%sMENU%s\n' "$C_BOLD" "$C_CYN" "$C_RESET"
  echo "  1) Status dashboard (refresh)"
  echo "  2) Clean large agent-tools (>${TOOL_SIZE_MB} MB)"
  echo "  3) Clean old Windows Cursor logs"
  echo "  4) Clean all (2+3+cache) — recommended"
  echo "  5) Soft reset cursor-server (WSL)"
  echo "  6) FULL tune-up (4 + 5)"
  echo "  7) OOM crash report"
  echo "  8) Create checkpoint template"
  echo "  9) Show checkpoint"
  echo " 10) Project test/report inventory"
  echo " 11) Tips — one chat without losing context"
  echo "  0) Exit"
  hr
}

interactive_menu() {
  while true; do
    show_menu
    printf '%sChoice [0-11]: %s' "$C_BOLD" "$C_RESET"
    read -r choice
    case "${choice:-}" in
      1) clear 2>/dev/null || true; print_dashboard ;;
      2) do_clean_agent_tools ;;
      3) do_clean_win_logs ;;
      4) do_clean_all ;;
      5) do_soft_reset ;;
      6) do_tuneup ;;
      7) do_oom_report ;;
      8) do_checkpoint_create ;;
      9) do_checkpoint_show ;;
      10) do_project_inventory ;;
      11) do_tips ;;
      0|q|Q) ok "Done."; exit 0 ;;
      *) bad "Invalid choice: $choice" ;;
    esac
    pause_enter
    clear 2>/dev/null || true
    print_dashboard
  done
}

# Legacy CLI (optional)
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "Run without arguments: ~/cursor_wsl_health.sh"
  exit 0
fi

if [[ -n "${1:-}" ]]; then
  case "$1" in
    status) print_dashboard ;;
    clean) do_clean_all ;;
    soft-reset) do_soft_reset ;;
    checkpoint) do_checkpoint_create ;;
    all) do_tuneup ;;
    *) echo "Unknown argument. Run without arguments for the menu."; exit 1 ;;
  esac
  exit 0
fi

clear 2>/dev/null || true
print_dashboard
interactive_menu
