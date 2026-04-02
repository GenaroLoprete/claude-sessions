# claude-sessions

A lightweight tool to track, browse, and resume your [Claude Code](https://docs.anthropic.com/en/docs/claude-code) sessions.

Ever lose track of what you were working on across multiple Claude Code sessions? `claude-sessions` automatically logs every session and lets you browse, search, and resume them with a single command.

## Features

- **Automatic session tracking** via Claude Code's `Stop` hook — no manual work needed
- **On-demand AI summaries** using Claude Haiku when you browse a session
- **Multi-topic support** — sessions split by `/clear` are summarized per topic
- **Summary caching** — Haiku is only called once per session, results are cached
- **Search** sessions by keyword across previews and cached summaries
- **Date filtering** with `--from` and `--to`
- **Orphan detection** — marks sessions whose transcript was deleted with `!`
- **Cleanup** old or orphan sessions with `--cleanup`
- **Minimum turn threshold** — sessions with fewer than 3 turns are not tracked

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed and authenticated
- Python 3.6+
- Bash

## Installation

```bash
git clone https://github.com/GenaroLoprete/claude-sessions.git
cd claude-sessions
bash install.sh
```

The installer will:
1. Copy the hook script to `~/.claude/hooks/`
2. Copy the `claude-sessions` CLI to `~/.local/bin/`
3. Configure the `Stop` hook in `~/.claude/settings.json`

> If you already have a `settings.json`, the installer will print the hook config for you to add manually.

## Usage

```bash
# Show last 10 sessions (default)
claude-sessions

# Show all sessions
claude-sessions --all

# Filter by date
claude-sessions --from 2025-03-01
claude-sessions --from 2025-03-01 --to 2025-03-15

# Search by keyword
claude-sessions --search "auth"
claude-sessions -s "payments"

# Clean up old sessions (e.g., older than 30 days)
claude-sessions --cleanup 30
```

### Interactive mode

When you run `claude-sessions`, you'll see a table like this:

```
    #  Date         Turns Topics  Directory                      Preview
  ───  ──────────── ───── ──────  ────────────────────────────── ────────────────────────────
    1  2025-04-02     134      2  ~                              quiero desarrollar algo nue...
    2  2025-04-01      66      1  ~/projects/payments            fix del bug en el endpoint ...
    3! 2025-03-28      78      1  ~/projects/api-gateway         revisar y mergear los PRs p...

  Select a session (number) or 'q' to quit:
```

- Select a number to see the AI-generated summary and the command to resume
- Sessions marked with `!` are orphans (transcript file was deleted)
- Summaries are generated once and cached — subsequent views are instant

### Resuming a session

After selecting a session, you'll see:

```
  Topic 1/2:
  - Tópico principal: Hook para logging automático de sesiones
  - Resumen:
    - Se diseñó un sistema de logging usando el hook Stop
    - Se creó comando claude-sessions para navegar sesiones
  - Estado: completado

  To resume: claude --resume 91cdbc19-74d8-4e1f-b28f-f4dded198cf0
```

Copy and paste the `claude --resume` command to pick up where you left off.

## How it works

1. **`Stop` hook** (`~/.claude/hooks/session-log.sh`): runs after every Claude response. Saves lightweight metadata (session ID, date, directory, first message preview, turn count, topic count) to `~/.claude/session-logs/<session-id>.json`. No AI calls — fast and free.

2. **`claude-sessions` CLI** (`~/.local/bin/claude-sessions`): reads the JSON metadata files and presents them in an interactive table. When you select a session, it calls `claude -p --model haiku` to generate a summary from the transcript. The summary is cached in the JSON file for instant future access.

3. **Topic splitting**: if a session contains `/clear` commands, the transcript is split into segments. Each segment gets its own summary, so you can see what was discussed before and after each `/clear`.

## File structure

```
~/.claude/
├── hooks/
│   └── session-log.sh          # Stop hook (installed by install.sh)
├── session-logs/
│   ├── <session-id>.json       # Session metadata + cached summaries
│   └── ...
└── settings.json               # Hook configuration
```

## Uninstall

```bash
cd claude-sessions
bash uninstall.sh
```

Session logs in `~/.claude/session-logs/` are preserved. Remove them manually if desired.

## License

[MIT](LICENSE)
