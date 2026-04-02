#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOKS_DIR="$HOME/.claude/hooks"
BIN_DIR="$HOME/.local/bin"
SETTINGS_FILE="$HOME/.claude/settings.json"
LOG_DIR="$HOME/.claude/session-logs"

echo "Installing claude-sessions..."

# Create directories
mkdir -p "$HOOKS_DIR" "$BIN_DIR" "$LOG_DIR"

# Copy hook script
cp "$SCRIPT_DIR/hooks/session-log.sh" "$HOOKS_DIR/session-log.sh"
chmod +x "$HOOKS_DIR/session-log.sh"
echo "  Installed hook: $HOOKS_DIR/session-log.sh"

# Copy CLI tool
cp "$SCRIPT_DIR/bin/claude-sessions" "$BIN_DIR/claude-sessions"
chmod +x "$BIN_DIR/claude-sessions"
echo "  Installed CLI:  $BIN_DIR/claude-sessions"

# Configure Stop hook in settings.json
if [ ! -f "$SETTINGS_FILE" ]; then
    # No settings file, create one
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/session-log.sh",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
EOF
    echo "  Created settings: $SETTINGS_FILE"
else
    # Settings file exists, check if hook is already configured
    if grep -q "session-log.sh" "$SETTINGS_FILE" 2>/dev/null; then
        echo "  Hook already configured in settings.json, skipping."
    else
        echo ""
        echo "  WARNING: $SETTINGS_FILE already exists."
        echo "  Please add the following hook manually to your settings.json:"
        echo ""
        echo '  {
    "hooks": {
      "Stop": [
        {
          "hooks": [
            {
              "type": "command",
              "command": "bash ~/.claude/hooks/session-log.sh",
              "timeout": 60
            }
          ]
        }
      ]
    }
  }'
        echo ""
    fi
fi

# Check if BIN_DIR is in PATH
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo ""
    echo "  WARNING: $BIN_DIR is not in your PATH."
    echo "  Add this to your shell profile (~/.bashrc or ~/.zshrc):"
    echo ""
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
fi

echo ""
echo "Installation complete!"
echo "  Start a new Claude Code session and the hook will begin tracking."
echo "  Run 'claude-sessions' to browse your sessions."
