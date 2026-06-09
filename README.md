# cursor-wsl-health

By **[Logic Encoder](https://logicencoder.com)** — small **public** bash utility for **Cursor IDE on Linux** (bare Ubuntu/Debian and **WSL2**). One repo, no `-overview`.

Interactive menu: health dashboard, safe cache clean, optional `cursor-server` soft reset — **one long agent chat** (Reload Window, not New Chat).

| Doc | Purpose |
|-----|---------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Functions, paths, platform detection |

GitHub: [logicencoder/cursor-wsl-health](https://github.com/logicencoder/cursor-wsl-health), branch **`main`**.

## Platforms

| Environment | What works |
|-------------|------------|
| **WSL2** | Full: Linux memory, cursor-server, agent-tools, Windows logs via `/mnt/c/Users/{WIN_USER}/...`, native `~/.config/Cursor/logs` if present |
| **Bare Linux** (Ubuntu, etc.) | Linux memory, cursor-server, agent-tools, `~/.config/Cursor/logs` — no `/mnt/c` needed |

Repo name keeps `wsl` for history; the script auto-detects **WSL** vs **Linux**.

## Why it exists

Cursor often hits **Electron renderer OOM** (`"reason":"oom"` in `cursor-sentry-events.log`). Large `agent-tools/*.txt` dumps and a multi-day `cursor-server` (~2 GB RSS) make long agent sessions worse.

## Install

```bash
git clone https://github.com/logicencoder/cursor-wsl-health.git ~/cursor-wsl-health
chmod +x ~/cursor-wsl-health/cursor_wsl_health.sh
ln -sf ~/cursor-wsl-health/cursor_wsl_health.sh ~/cursor_wsl_health.sh
~/cursor_wsl_health.sh
```

Run in a **terminal** (TTY). On WSL, not a non-interactive Cursor output panel.

## Workflow

1. **Menu 4** — clean all
2. **Ctrl+Shift+P → Developer: Reload Window** — same chat
3. **Menu 6** when `cursor-server` uptime is multi-day

## Menu

| # | Action |
|---|--------|
| 1 | Status dashboard |
| 2 | Delete agent-tools `.txt` > 10 MB |
| 3 | Delete old Cursor logs (>7 days) — WSL + Linux paths |
| 4 | 2 + 3 + page cache (recommended) |
| 5 | Soft reset `cursor-server` |
| 6 | Full tune-up (4 + 5) |
| 7 | OOM crash report |
| 8–11 | Checkpoint, inventory, tips |

## Environment variables

| Variable | Default | Meaning |
|----------|---------|---------|
| `WIN_USER` | `Lojzek` | WSL only: Windows user for `/mnt/c/Users/...` |
| `CURSOR_HEALTH_PROJECT` | `~/cex_dex_arb_app` | Optional project inventory/checkpoint |
| `CURSOR_HEALTH_CHECKPOINT` | `{project}/.cursor_session_checkpoint.md` | Session notes |
| `CURSOR_HEALTH_REPORTS` / `CURSOR_HEALTH_SCRIPTS` | `{project}/reports`, `scripts` | Never deleted |
| `NO_COLOR` | unset | Disable ANSI colors |

## Never deleted by clean

Chat transcripts, project reports/scripts, source code, git, existing checkpoint.

## CLI

```bash
~/cursor_wsl_health.sh status
~/cursor_wsl_health.sh clean
~/cursor_wsl_health.sh soft-reset
~/cursor_wsl_health.sh all
```

**Logic Encoder** — [logicencoder.com](https://logicencoder.com) · [GitHub](https://github.com/logicencoder/cursor-wsl-health)

Use at your own risk.
