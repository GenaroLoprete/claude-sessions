#!/bin/bash
set -e

HOOKS_DIR="$HOME/.claude/hooks"
BIN_DIR="$HOME/.local/bin"
LOG_DIR="$HOME/.claude/session-logs"

echo "Uninstalling claude-sessions..."

# Remove hook script
if [ -f "$HOOKS_DIR/session-log.sh" ]; then
    rm "$HOOKS_DIR/session-log.sh"
    echo "  Removed: $HOOKS_DIR/session-log.sh"
fi

# Remove CLI tool
if [ -f "$BIN_DIR/claude-sessions" ]; then
    rm "$BIN_DIR/claude-sessions"
    echo "  Removed: $BIN_DIR/claude-sessions"
fi

echo ""
echo "  NOTE: Session logs in $LOG_DIR were NOT deleted."
echo "  Remove them manually if you want: rm -rf $LOG_DIR"
echo ""
echo "  NOTE: The Stop hook entry in ~/.claude/settings.json was NOT removed."
echo "  Remove it manually if needed."
echo ""
echo "Uninstall complete."
