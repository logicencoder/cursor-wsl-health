# Architecture — cursor-wsl-health

Single-file bash application: `cursor_wsl_health.sh`. No dependencies beyond standard Linux utilities (`find`, `du`, `free`, `pgrep`, `ps`, optional `numfmt`, optional `sudo` for `drop_caches`).

## Runtime layout

```
~/cursor-wsl-health/
  cursor_wsl_health.sh   # main script
  README.md
  ARCHITECTURE.md
  REPOS.md

~/cursor_wsl_health.sh   # symlink → repo script (operator entry point)
```

## Configuration (top of script)

| Symbol | Source | Role |
|--------|--------|------|
| `HOME_LOJZO` | `$HOME` | WSL home |
| `WIN_USER` | env, default `Lojzek` | Windows profile for log path |
| `WIN_LOG_ROOT` | `/mnt/c/Users/{WIN_USER}/AppData/Roaming/Cursor/logs` | Windows Cursor logs via WSL mount |
| `AGENT_ROOT` | `~/.cursor/projects` | All Cursor project agent data |
| `PROJECT_ROOT` | `CURSOR_HEALTH_PROJECT` or `~/cex_dex_arb_app` | Inventory/checkpoint project |
| `STATE_FILE` | `CURSOR_HEALTH_CHECKPOINT` or `{PROJECT_ROOT}/.cursor_session_checkpoint.md` | Operator session notes |
| `PROJECT_REPORTS` | `CURSOR_HEALTH_REPORTS` or `{PROJECT_ROOT}/reports` | Read-only inventory |
| `PROJECT_SCRIPTS` | `CURSOR_HEALTH_SCRIPTS` or `{PROJECT_ROOT}/scripts` | Read-only inventory |
| `TOOL_SIZE_MB` | `10` | Threshold for agent-tools deletion |
| `LOG_AGE_DAYS` | `7` | Threshold for Windows log folder deletion |

## ANSI colors

Colors use `$'\033[Nm'` syntax (real escapes). Disabled when stdout is not a TTY or `NO_COLOR` is set.

## Core functions

| Function | Purpose |
|----------|---------|
| `print_dashboard` | Full status: WSL memory, cursor-server RSS/uptime, agent-tools stats, top transcripts, OOM count, project inventory, checkpoint |
| `agent_tools_stats` | Count/size `*/agent-tools/*.txt`; sets `LARGE_COUNT`, `LARGE_BYTES`, `TOTAL_TXT`, `TOTAL_TXT_BYTES` |
| `count_oom_events` | Grep `"reason":"oom"` in `cursor-sentry-events.log` under `WIN_LOG_ROOT` |
| `cursor_server_pid` | `pgrep` for `cursor-server.*server-main` |
| `do_clean_agent_tools` | `rm` agent-tools `.txt` files larger than `TOOL_SIZE_MB` |
| `do_clean_win_logs` | `rm -rf` log session dirs older than `LOG_AGE_DAYS` |
| `do_drop_caches` | `echo 3 > /proc/sys/vm/drop_caches` via sudo |
| `do_soft_reset` | `kill` cursor-server main + bootstrap forks |
| `do_checkpoint_create` | Write template markdown if missing (never overwrite) |

## Menu flow

```
interactive_menu loop
  → show_menu
  → read choice
  → run action
  → pause_enter
  → clear + print_dashboard
```

Exit on `0`, `q`, or `Q`.

## Safety model

**Deletable (menu 2–4):**

- `~/.cursor/projects/*/agent-tools/*.txt` where size > 10 MB
- `WIN_LOG_ROOT/*/` directories with mtime > 7 days
- Linux page cache (optional, menu 4)

**Never touched:**

- `agent-transcripts/**/*.jsonl`
- `PROJECT_REPORTS`, `PROJECT_SCRIPTS`, git trees, `STATE_FILE` (except menu 8 creates empty template)

## OOM diagnosis

Crashes are attributed to **Windows Electron renderer OOM**, not WSL kernel OOM. Evidence: `cursor-sentry-events.log` lines containing `"reason":"oom"` while `free` shows high WSL `available`. Mitigation: reduce renderer pressure (close extra windows, disable Browser MCP when idle), clean agent-tools, Reload Window, occasional soft reset.

## One-chat policy

Cleaning and server reset do **not** delete chat history. Operator must use **Developer: Reload Window** on the **same** chat tab. Checkpoint file provides project context after reload via @-mention.

## File map

| File | Lines (approx) | Responsibility |
|------|----------------|----------------|
| `cursor_wsl_health.sh` | ~460 | Entire application |

No tests, no CI, no package manager — intentional minimal scope for WSL operator use.
