#!/usr/bin/env bash
# Stop hook: block end-of-turn if the agent justified stopping with
# "pre-existing failure" / "existed on main" / "not caused by my changes"
# reasoning. Only fires in autonomous mode.
set -u
input=$(cat)
echo "$input" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0

printf '%s' "$input" | bash "$(dirname "$0")/is-autonomous.sh" || exit 0

transcript=$(printf '%s' "$input" | jq -r '.transcript_path // ""' 2>/dev/null)
[ -z "$transcript" ] && exit 0
[ -f "$transcript" ] || exit 0

last=$(jq -s '[.[] | select(.message.role == "assistant")] | .[-1].message.content | if type == "array" then map(.text // "") | join(" ") else . // "" end' "$transcript" 2>/dev/null)

echo "$last" | grep -iEq '(pre[- ]?existing[[:space:]]+(failure|issue|problem)|existed[[:space:]]+on[[:space:]]+main|not[[:space:]]+caused[[:space:]]+by[[:space:]]+(my|this|the)[[:space:]]+changes?|pre[- ]?existing[[:space:]]+(test|ci))' || exit 0

jq -cn '{decision: "block", reason: "NO SUCH THING AS A PRE-EXISTING FAILURE. CI passes on main. If CI fails on this PR branch, either your change broke it or your local setup is stale — investigate both. Do not justify stopping with pre-existing/main-also-broken/not-my-changes reasoning. Either fix it or escalate to the user with a specific concrete reason (which CI job, which line, what you tried)."}'
