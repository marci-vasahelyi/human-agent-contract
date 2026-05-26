#!/usr/bin/env bash
# PostToolUse for Bash: after a `git push`, if autonomous mode is active,
# hard-block until /post-push runs (which opens the PR if needed and hands
# off to /babysit-pr). Silent in cooperative mode.
set -u
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)
echo "$cmd" | grep -Eq '(^|[[:space:]])git[[:space:]]+push([[:space:]]|$)' || exit 0

printf '%s' "$input" | bash "$(dirname "$0")/is-autonomous.sh" || exit 0

jq -cn '{decision: "block", reason: "Push detected. You MUST run /post-push next — no exceptions, no skipping for trivial commits. /post-push opens the PR if needed and hands off to /babysit-pr which monitors CI and review. This is the team workflow rule. Do not invent reasons (cost, triviality, scope) to skip it."}'
