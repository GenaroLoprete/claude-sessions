#!/bin/bash

# Stop hook: saves lightweight session metadata (no model calls)
# Runs after each Claude response

# Prevent recursive execution
[ -n "$SESSION_LOG_RUNNING" ] && exit 0
export SESSION_LOG_RUNNING=1

INPUT=$(cat)
LOG_DIR="$HOME/.claude/session-logs"
mkdir -p "$LOG_DIR"

# Save input to temp file so python can read it (heredoc and pipe conflict on stdin)
TMPFILE=$(mktemp)
echo "$INPUT" > "$TMPFILE"

python3 - "$TMPFILE" << 'PYEOF'
import sys, json, os
from datetime import datetime

tmpfile = sys.argv[1]
try:
    with open(tmpfile) as f:
        hook_input = json.load(f)
finally:
    os.unlink(tmpfile)

session_id = hook_input.get("session_id", "")
transcript_path = hook_input.get("transcript_path", "")
cwd = hook_input.get("cwd", "")

if not session_id or not transcript_path or not os.path.isfile(transcript_path):
    sys.exit(0)

log_dir = os.path.expanduser("~/.claude/session-logs")
log_file = os.path.join(log_dir, f"{session_id}.json")

# Parse transcript: extract segments (split by /clear), turns, and preview
# Transcript format: {"type": "user", "isMeta": bool, "message": {"role": "user", "content": "..."}}
segments = 1
preview = ""
turns = 0
try:
    with open(transcript_path) as f:
        for line in f:
            try:
                entry = json.loads(line.strip())

                # Detect /clear commands to count segments
                if entry.get("type") == "user":
                    content = entry.get("message", {}).get("content", "")
                    if isinstance(content, str) and "<command-name>/clear</command-name>" in content:
                        segments += 1
                        continue

                # Only count actual user messages, skip meta/system/snapshots
                if entry.get("type") != "user" or entry.get("isMeta", False):
                    continue
                turns += 1
                if not preview:
                    content = entry.get("message", {}).get("content", "")
                    if isinstance(content, list):
                        for block in content:
                            if isinstance(block, dict) and block.get("type") == "text":
                                preview = block["text"][:100]
                                break
                    elif isinstance(content, str):
                        # Skip XML tags (system commands, etc.)
                        if not content.startswith("<"):
                            preview = content[:100]
            except (json.JSONDecodeError, KeyError):
                continue
except Exception:
    pass

if not preview:
    preview = "(empty session)"

preview = preview.replace("\n", " ")

# Skip sessions with fewer than 3 turns (too short to be useful)
if turns < 3:
    sys.exit(0)

# Load existing data to preserve cached summaries
existing = {}
if os.path.isfile(log_file):
    try:
        with open(log_file) as f:
            existing = json.load(f)
    except (json.JSONDecodeError, OSError):
        pass

data = {
    "session_id": session_id,
    "date": datetime.now().strftime("%Y-%m-%d %H:%M"),
    "cwd": cwd,
    "preview": preview,
    "turns": turns,
    "segments": segments,
    "transcript_path": transcript_path,
}

# Invalidate cached summaries if segment count changed
old_segments = existing.get("segments", 1)
if segments == old_segments and "summaries" in existing:
    data["summaries"] = existing["summaries"]

with open(log_file, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
PYEOF
