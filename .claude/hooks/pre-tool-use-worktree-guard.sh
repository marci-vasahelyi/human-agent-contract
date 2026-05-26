#!/usr/bin/env bash
# PreToolUse guard for file-modifying tools: block the call unless cwd is
# inside a git worktree (not the main checkout).
set -u
input=$(cat)

printf '%s' "$input" | bash "$(dirname "$0")/is-autonomous.sh" || exit 0

cwd=$(printf '%s' "$input" | jq -r '.cwd // ""' 2>/dev/null)
[ -z "$cwd" ] && exit 0
cd "$cwd" 2>/dev/null || exit 0

gd=$(git rev-parse --git-dir 2>/dev/null)
gc=$(git rev-parse --git-common-dir 2>/dev/null)
if [ -n "$gd" ] && [ -n "$gc" ] && \
   [ "$(cd "$gd" 2>/dev/null && pwd)" != "$(cd "$gc" 2>/dev/null && pwd)" ]; then
  exit 0
fi

jq -cn '{decision: "block", reason: "Not in a worktree — call EnterWorktree first."}'
