#!/usr/bin/env bash
# Reads hook JSON from stdin, decides if autonomous mode is active for the
# current session. Per-session override file wins; otherwise the global
# default applies. Exits 0 if autonomous, 1 if not.
set -u
input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // ""' 2>/dev/null)
override="${CLAUDE_PROJECT_DIR:-.}/.claude/.autonomous.d/$sid"
if [ -n "$sid" ] && [ -f "$override" ]; then
  mode=$(cat "$override" 2>/dev/null)
else
  mode=$(cat "${CLAUDE_PROJECT_DIR:-.}/.claude/.autonomous" 2>/dev/null)
fi
[ "$mode" = "on" ]
