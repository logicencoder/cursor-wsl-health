# cursor-wsl-health

Small **public** bash utility for **Cursor IDE on Windows + WSL2** — one repo, no separate overview (not a product-sized app).

Interactive menu: WSL/Cursor health dashboard, safe cache clean, optional `cursor-server` soft reset — while keeping **one long agent chat** (Reload Window, not New Chat).

| Doc | Purpose |
|-----|---------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Functions, paths, safety boundaries |

GitHub: [logicencoder/cursor-wsl-health](https://github.com/logicencoder/cursor-wsl-health), branch **`main`**.

## Why it exists

Cursor on Windows often crashes with **Electron renderer OOM** (`"reason":"oom"` in `cursor-sentry-events.log`), even when WSL has plenty of RAM. Large `agent-tools/*.txt` dumps and a multi-day `cursor-server` (~2 GB RSS) make long agent sessions worse.

| Symptom | Likely cause | This tool |
|---------|--------------|-----------|
| Freeze/reload after heavy agent use | Windows renderer OOM | Cleans large tool dumps; counts OOM in logs |
| WSL RAM OK but Cursor still dies | Crash on Windows, not WSL OOM | Dashboard shows both sides |
| Sluggish chat after days | Big transcript + stale server | Transcript sizes; soft reset (5/6) |
| Afraid cleanup kills context | Transcripts stay on disk | **Reload Window**, same chat |

## Install

```bash
git clone https://github.com/logicencoder/cursor-wsl-health.git ~/cursor-wsl-health
chmod +x ~/cursor-wsl-health/cursor_wsl_health.sh
ln -sf ~/cursor-wsl-health/cursor_wsl_health.sh ~/cursor_wsl_health.sh
~/cursor_wsl_health.sh
```

Run in a **WSL terminal** (TTY), not a non-interactive output panel.

## Workflow

1. **Menu 4** — clean all (usual)
2. **Ctrl+Shift+P → Developer: Reload Window** — same chat
3. **Menu 6** only when `cursor-server` uptime is multi-day
4. After reload: @-mention `.cursor_session_checkpoint.md` in your project if needed

## Menu

| # | Action |
|---|--------|
| 1 | Status dashboard |
| 2 | Delete agent-tools `.txt` > 10 MB |
| 3 | Delete Windows Cursor logs > 7 days |
| 4 | 2 + 3 + page cache (recommended) |
| 5 | Soft reset WSL `cursor-server` |
| 6 | Full tune-up (4 + 5) |
| 7 | OOM crash report |
| 8–11 | Checkpoint, inventory, tips |

## Environment variables

| Variable | Default | Meaning |
|----------|---------|---------|
| `WIN_USER` | `Lojzek` | Windows user for `/mnt/c/Users/...` |
| `CURSOR_HEALTH_PROJECT` | `~/cex_dex_arb_app` | Project for inventory/checkpoint |
| `CURSOR_HEALTH_CHECKPOINT` | `{project}/.cursor_session_checkpoint.md` | Session notes file |
| `CURSOR_HEALTH_REPORTS` / `CURSOR_HEALTH_SCRIPTS` | `{project}/reports`, `scripts` | Never deleted by clean |
| `NO_COLOR` | unset | Disable ANSI colors |

## Never deleted by clean

Chat transcripts, project reports/scripts, source code, git, existing checkpoint.

## CLI shortcuts

```bash
~/cursor_wsl_health.sh status
~/cursor_wsl_health.sh clean
~/cursor_wsl_health.sh soft-reset
~/cursor_wsl_health.sh all
```

## What it is not

Not Cursor support, not a transcript editor, not for SOL/Hostinger deploy — WSL dev helper only.

© Logic Encoder — use at your own risk.
