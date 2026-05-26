#!/usr/bin/env bash
# PreToolUse guard for Bash: block `git add -f` of anything under
# .claude/plans (local-only scratchpad, not PR content).
set -u
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Allow global flags between `git` and `add` (e.g. `git -C repo add -f …`).
echo "$cmd" | grep -Eq '(^|[[:space:]])git([[:space:]]+(-C|--git-dir|--work-tree|--exec-path)[[:space:]]*=?[[:space:]]*[^[:space:]]+)*[[:space:]]+add\b' || exit 0
echo "$cmd" | grep -Eq -- '(-f\b|--force\b)' || exit 0
echo "$cmd" | grep -Fq '.claude/plans'       || exit 0

jq -cn '{decision: "block", reason: ".claude/plans/ is local-only. Never force-add it. The plan is your scratchpad, not PR content."}'
