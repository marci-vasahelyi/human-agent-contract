#!/usr/bin/env bash
# SessionEnd hook: remove any per-session mode override and last-injected
# state files for the ending session so no stale state accumulates.
set -u
input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // ""' 2>/dev/null)
[ -n "$sid" ] || exit 0
proj="${CLAUDE_PROJECT_DIR:-.}"
rm -f \
  "$proj/.claude/.autonomous.d/$sid" \
  "$proj/.claude/.autonomous-state.d/$sid"
exit 0
