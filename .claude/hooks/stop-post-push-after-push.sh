#!/usr/bin/env bash
# Stop hook: deterministic check that /post-push ran after any `git push`
# in this turn. Without this, the agent can quietly skip /post-push despite
# the PostToolUse push reminder. Silent in cooperative mode.
set -u
input=$(cat)
echo "$input" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0

printf '%s' "$input" | bash "$(dirname "$0")/is-autonomous.sh" || exit 0

transcript=$(printf '%s' "$input" | jq -r '.transcript_path // ""' 2>/dev/null)
[ -z "$transcript" ] && exit 0
[ -f "$transcript" ] || exit 0

# Scan this turn only: the slice of assistant tool_use events after the
# most recent user-typed prompt (excluding tool_result user messages).
# Return "push" for each git-push Bash call, "postpush" for each
# Skill(post-push) call, in order. If the last "push" is not followed
# by a "postpush", block.
sequence=$(jq -rs '
  # Find index of last real user prompt (a user message whose content
  # is a plain string, not a tool_result array).
  (
    [.[] | .message
      | select(.role == "user")
      | select((.content | type) == "string")
    ] | length
  ) as $_ |
  (
    [range(0; length) as $i | .[$i] | .message |
      select(.role == "user") |
      select((.content | type) == "string") | $i
    ] | last // -1
  ) as $lastUser |
  [.[$lastUser + 1:][] |
    .message |
    select(.role == "assistant") |
    (.content // []) |
    if type == "array" then .[] else empty end |
    select(.type == "tool_use") |
    if .name == "Bash" and ((.input.command // "") | test("(^|[[:space:]])git[[:space:]]+push([[:space:]]|$)"))
      then "push"
    elif (.name == "Skill") and ((.input.skill // "") == "post-push")
      then "postpush"
    else empty
    end
  ] | join(",")
' "$transcript" 2>/dev/null)

# If no push happened this turn, nothing to check. The sequence is a comma-
# joined list of tokens "push" and "postpush"; match on the token boundary
# so "postpush" alone doesn't trigger the check.
echo "$sequence" | grep -Eq '(^|,)push(,|$)' || exit 0

# If the sequence ends with a `push` token (no `postpush` after it), block.
case ",$sequence," in
  *,push,) ;;
  *) exit 0 ;;
esac

jq -cn '{decision: "block", reason: "You pushed this turn but did not invoke /post-push. The push hook said you MUST run /post-push next — no exceptions. /post-push ensures the PR exists, ensures the babysit-pr cron is scheduled, and runs /review + /diagnose subagents. Invoke /post-push now via Skill before stopping."}'
