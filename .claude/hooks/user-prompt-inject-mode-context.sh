#!/usr/bin/env bash
# UserPromptSubmit hook: inject the autonomous contract while autonomous is
# active, and a one-shot cancellation notice the first turn after a switch
# back to cooperative. Tracks per-session last-injected mode so the
# cancellation fires exactly once.
set -u
input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // ""' 2>/dev/null)
proj="${CLAUDE_PROJECT_DIR:-.}"

override="$proj/.claude/.autonomous.d/$sid"
if [ -n "$sid" ] && [ -f "$override" ]; then
  mode=$(cat "$override" 2>/dev/null)
else
  mode=$(cat "$proj/.claude/.autonomous" 2>/dev/null)
fi

state_file="$proj/.claude/.autonomous-state.d/$sid"
last="off"
[ -n "$sid" ] && [ -f "$state_file" ] && last=$(cat "$state_file" 2>/dev/null)

write_state() {
  [ -n "$sid" ] || return 0
  mkdir -p "$proj/.claude/.autonomous-state.d"
  printf '%s' "$1" > "$state_file"
}

if [ "$mode" = "on" ]; then
  write_state on
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"Autonomous mode is on. CONTRACT: human attention is the scarce resource; agent compute is free. The carefully crafted interface where you and the human meet is the draft PR, not constant clarification. Even a one-line ticket means: do your best-effort initial implementation, push a draft PR, let the human evaluate code instead of answering 17 questions. Worst case they close the PR and you go back to planning; best case the first PR is shippable. RULES: prefer decisions over questions — if you would surface 2+ options, pick one, note why, proceed. Asking costs the human a context switch; picking + logging costs you seconds. Log non-obvious calls at .claude/uncertainties/<kebab-topic>.md before pulling the human in. When you do brief them, do it like a manager update — plain English, compact, high-level: what happened, why, blockers."}}'
elif [ "$last" = "on" ]; then
  write_state off
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"Cooperative mode is now active for this session (you switched from autonomous mid-session). The autonomous-mode CONTRACT and RULES injected on earlier turns no longer apply. Default behaviour resumes: ask before non-trivial decisions, do not push without confirmation, do not log to .claude/uncertainties — talk through the change with the human in the conversation. Disregard prior decide-do-not-ask priming."}}'
else
  exit 0
fi
