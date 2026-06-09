# cursor-wsl-health

**Private** Logic Encoder operator tool for **Cursor IDE on Windows + WSL2**.

Interactive bash menu that monitors WSL/Cursor health, cleans safe cache (agent tool dumps, old Windows logs), and optionally soft-resets `cursor-server` — while keeping **one long agent chat** (Reload Window, not New Chat).

| Doc | Purpose |
|-----|---------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Menu actions, paths, safety boundaries, env vars |
| [REPOS.md](REPOS.md) | Related repositories |

GitHub: **private** — `logicencoder/cursor-wsl-health`, branch **`main`**.

## Problem it solves

Windows Cursor often crashes with **Electron renderer OOM** (`"reason":"oom"` in `cursor-sentry-events.log`), even when WSL has plenty of RAM. Large `agent-tools/*.txt` dumps under `~/.cursor/projects/` and a multi-day `cursor-server` process (~2 GB RSS) make this worse. This script cleans only safe caches and shows what to do next.

## Install (WSL)

```bash
git clone https://github.com/logicencoder/cursor-wsl-health.git ~/cursor-wsl-health
chmod +x ~/cursor-wsl-health/cursor_wsl_health.sh
ln -sf ~/cursor-wsl-health/cursor_wsl_health.sh ~/cursor_wsl_health.sh
```

Run:

```bash
~/cursor_wsl_health.sh
```

No CLI arguments required — use the numbered menu.

## Recommended workflow

1. **Menu 4** — clean all (agent-tools + old Windows logs + optional `drop_caches`)
2. **Ctrl+Shift+P → Developer: Reload Window** — same chat, not New Chat
3. **Menu 5** or **6** only when `cursor-server` uptime is multi-day
4. After crash/reload: @-mention `.cursor_session_checkpoint.md` in your project

## Menu summary

| # | Action |
|---|--------|
| 1 | Status dashboard |
| 2 | Delete agent-tools `.txt` files larger than 10 MB |
| 3 | Delete Windows Cursor log folders older than 7 days |
| 4 | All of 2+3 + Linux page cache (recommended) |
| 5 | Soft reset WSL `cursor-server` |
| 6 | Full tune-up (4 + 5) |
| 7 | OOM crash report from Windows logs |
| 8–11 | Checkpoint template, inventory, tips |

## Environment variables

| Variable | Default | Meaning |
|----------|---------|---------|
| `WIN_USER` | `Lojzek` | Windows username for `/mnt/c/Users/...` |
| `CURSOR_HEALTH_PROJECT` | `~/cex_dex_arb_app` | Project root for inventory/checkpoint |
| `CURSOR_HEALTH_PROJECT_LABEL` | basename of project | Dashboard label |
| `CURSOR_HEALTH_CHECKPOINT` | `{project}/.cursor_session_checkpoint.md` | Session checkpoint file |
| `CURSOR_HEALTH_REPORTS` | `{project}/reports` | Reports dir (never deleted by clean) |
| `CURSOR_HEALTH_SCRIPTS` | `{project}/scripts` | Scripts dir (never deleted by clean) |
| `NO_COLOR` | unset | Disable ANSI colors |

## What clean never deletes

- Chat transcripts (`agent-transcripts/*.jsonl`)
- Project `reports/`, `scripts/`, source code, git history
- Session checkpoint file (only created if missing via menu 8)

## Legacy CLI

```bash
~/cursor_wsl_health.sh status
~/cursor_wsl_health.sh clean
~/cursor_wsl_health.sh soft-reset
~/cursor_wsl_health.sh all
```

## Prod path

WSL dev only: `~/cursor-wsl-health/` with symlink `~/cursor_wsl_health.sh`. Not deployed to SOL or Hostinger.
