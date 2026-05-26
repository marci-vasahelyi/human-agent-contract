---
name: post-push
description: MUST run after every `git push` (the PostToolUse push hook nudges; a Stop hook deterministically blocks the turn if you skip it). Ensures a PR exists, ensures a single recurring `/babysit-pr` loop is scheduled for that PR (idempotent), and spawns `/review` + `/diagnose` as parallel subagents on every push. No exceptions for "trivial" commits.
metadata:
  tags: workflow, review, automation
---

## Mental model

If a PR is open, `/babysit-pr` runs on a recurring loop (e.g. every 20 minutes) via a cron created here. **That cron is the only scheduler.** `/post-push` doesn't invoke `/babysit-pr` directly, and `/babysit-pr` does not self-schedule — either would create competing crons that quietly multiply.

Per-push work (`/review` + `/diagnose`) runs every time `/post-push` fires.

## Flow

1. **Ensure PR exists.** Look up the current branch's PR. If none, open a draft PR first. (For the human-agent-contract layout this is `gh pr view --json number -q .number`; adapt to whatever your project uses.)

2. **Ensure babysit cron exists.** Run `CronList`. If a cron whose prompt is `/babysit-pr <PR>` (or equivalent) already exists, do nothing. Otherwise: `Skill(loop, args: "<interval> /babysit-pr <PR>")`. Pick the interval based on your CI duration — 20 min is a reasonable default for most repos.

3. **Spawn `/review` and `/diagnose` as parallel subagents.** Single message, two Agent tool calls. Subagents keep their verbose output out of the main context — the controller only sees their typed-status return per the Subagent Return Protocol in `AGENTS.md`.

## Rules

- The babysit cron is the **single source of truth** for recurrence. Do not invoke `/babysit-pr` directly from here, and `/babysit-pr` itself must not self-schedule.
- `/review` and `/diagnose` run every push. Both are silent when clean.
- If the last commit message contains `post-push fix`, skip to avoid loops.
- This skill is enforced. The Stop hook scans the current turn's tool calls and blocks if a `git push` happened with no subsequent `Skill(post-push)` invocation. Do not invent reasons (cost, triviality, scope) to skip it.
