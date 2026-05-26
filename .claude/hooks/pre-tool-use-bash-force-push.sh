#!/usr/bin/env bash
# PreToolUse guard for Bash: block `git push -f` / --force / --force-with-lease.
# Force-push is destructive — require explicit human authorization.
set -u
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Allow global flags between `git` and `push` (e.g. `git -C repo push`,
# `git --git-dir=… push`).
echo "$cmd" | grep -Eq '(^|[[:space:]])git([[:space:]]+(-C|--git-dir|--work-tree|--exec-path)[[:space:]]*=?[[:space:]]*[^[:space:]]+)*[[:space:]]+push\b' || exit 0
echo "$cmd" | grep -Eq -- '(-f\b|--force\b|--force-with-lease\b)' || exit 0

jq -cn '{decision: "block", reason: "Force-push detected. Force-push is destructive — it rewrites history on a shared branch and can lose other people’s commits. Never force-push without explicit human authorization in the current conversation. If you genuinely need to rewrite history, ask the user first. Safer alternatives: new revert commit, new commit on top, or open a new PR."}'
