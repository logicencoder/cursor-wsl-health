# Architecture — cursor-wsl-health

**Logic Encoder** — [logicencoder.com](https://logicencoder.com) · [repo](https://github.com/logicencoder/cursor-wsl-health) (**public**)

Single-file bash application: `cursor_wsl_health.sh`. GNU/Linux (Ubuntu, WSL2). Utilities: `find`, `du`, `free`, `pgrep`, `ps`, optional `numfmt`, optional `sudo` for `drop_caches`.

## Platform detection

| Function | Logic |
|----------|--------|
| `is_wsl()` | `WSL_DISTRO_NAME` or `microsoft`/`wsl` in `/proc/version` |
| `init_platform()` | Sets `PLATFORM_LABEL` (`WSL` or `Linux`) and `CURSOR_LOG_ROOTS[]` |

**Log roots** (all that exist):

| Platform | Path |
|----------|------|
| WSL | `/mnt/c/Users/{WIN_USER}/AppData/Roaming/Cursor/logs` |
| Linux (incl. WSL) | `~/.config/Cursor/logs` |

OOM grep and log clean iterate **all** roots in `CURSOR_LOG_ROOTS`.

## Configuration

| Symbol | Source | Role |
|--------|--------|------|
| `HOME_DIR` | `$HOME` | User home |
| `WIN_USER` | env, default `Lojzek` | WSL: Windows profile for `/mnt/c` |
| `AGENT_ROOT` | `~/.cursor/projects` | Agent tool dumps and transcripts |
| `PROJECT_ROOT` | `CURSOR_HEALTH_PROJECT` | Optional inventory/checkpoint project |
| `STATE_FILE` | `CURSOR_HEALTH_CHECKPOINT` | Session checkpoint markdown |
| `TOOL_SIZE_MB` | `10` | agent-tools deletion threshold |
| `LOG_AGE_DAYS` | `7` | Old log session folder threshold |

## Core functions

| Function | Purpose |
|----------|---------|
| `print_dashboard` | Memory, cursor-server, agent-tools, transcripts, OOM, optional project, checkpoint |
| `count_oom_events` / `grep_oom_timestamps` | Across all `CURSOR_LOG_ROOTS` |
| `do_clean_agent_tools` | Remove large `agent-tools/*.txt` |
| `do_clean_cursor_logs` | Remove old log session dirs on every root |
| `do_soft_reset` | Stop `cursor-server` (Linux remote or WSL) |

## Safety model

**Deletable:** large agent-tools, old Cursor log sessions, optional page cache.

**Never touched:** `agent-transcripts/*.jsonl`, project reports/scripts, git, existing checkpoint.

## Visibility

**Public** GitHub — small shareable utility; no `-overview` repo.

---

© [Logic Encoder](https://logicencoder.com)
