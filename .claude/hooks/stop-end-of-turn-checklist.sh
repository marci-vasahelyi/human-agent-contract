#!/usr/bin/env bash
# Stop hook: end-of-turn checklist for autonomous mode. Skipped if the
# hook is firing recursively (stop_hook_active) or in cooperative mode.
set -u
input=$(cat)
echo "$input" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0

printf '%s' "$input" | bash "$(dirname "$0")/is-autonomous.sh" || exit 0

jq -cn '{decision: "block", reason: "END-OF-TURN CHECKLIST (autonomous mode): (1) Any committed work without a PR? Open a draft PR. (2) Pushed since last triad? Run /post-push. (3) About to end with a question instead of a decision? Make the call yourself, note why. (4) Defer-bias check: did you defer or punt anything this turn? Run the three-question test on each item: (a) same theme as the PR title / task — reviewer-suggested completeness on the PR'"'"'s core theme is scope, not adjacent; (b) would a senior reviewer call the merged PR incomplete without it; (c) under ~30 min of work in files you already touched. If yes to all three, build it now. If you still defer, state which question failed in one line. (5) Non-obvious calls made this turn? Log them at .claude/uncertainties/<kebab-topic>.md. (6) Briefing the human? Plain English, compact, high-level — what happened, why, blockers."}'
