# Architecture — cursor-health

**Logic Encoder** — [logicencoder.com](https://logicencoder.com) · [repo](https://github.com/logicencoder/cursor-health) (**public**)

Single-file bash application: `cursor_health.sh`. GNU/Linux: bare Ubuntu/Debian and WSL2. Utilities: `find`, `du`, `free`, `pgrep`, `ps`, optional `numfmt`, optional `sudo` for `drop_caches`.

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

## Runtime layout

```
~/cursor-health/
  cursor_health.sh
  README.md
  ARCHITECTURE.md
  REPOS.md

~/cursor_health.sh   # optional symlink
```

## Configuration

| Symbol | Source | Role |
|--------|--------|------|
| `HOME_DIR` | `$HOME` | User home |
| `WIN_USER` | env, default `Lojzek` | WSL: Windows profile for `/mnt/c` |
| `AGENT_ROOT` | `~/.cursor/projects` | Agent tool dumps and transcripts |
| `PROJECT_ROOT` | `CURSOR_HEALTH_PROJECT` | Optional inventory/checkpoint project |
| `TOOL_SIZE_MB` | `10` | agent-tools deletion threshold |
| `LOG_AGE_DAYS` | `7` | Old log session folder threshold |

## Safety model

**Deletable:** large agent-tools, old Cursor log sessions, optional page cache.

**Never touched:** `agent-transcripts/*.jsonl`, project reports/scripts, git, existing checkpoint.

## Visibility

**Public** GitHub — small shareable utility; no `-overview` repo.

---

© [Logic Encoder](https://logicencoder.com)
