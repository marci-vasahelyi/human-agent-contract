---
name: pickup
description: Drive a task end-to-end to a draft PR with a working slice. Research, slice, implement, verify locally, push, open the PR — that's the first human surface. Auto-invoke when a new session opens with a task-shaped first message, or when a conversation transitions to "ok do it".
metadata:
  tags: workflow, driver
---

## Flow

1. **Identify the task.** Task description / branch name / issue link? Use it. Nothing obvious? Ask once: *"What do you want to pick up?"*

2. **Worktree on latest main.** `git fetch origin main`, then `EnterWorktree` named after the task in kebab-case (e.g. `fix-login-redirect`, `add-drizzle-schema`). Symlink `node_modules` per AGENTS.md if applicable.

3. **Research.** `/figma-extract` for designs, project docs first then code. Web search for non-trivial libraries, specs, CVEs. Don't dump research at the user — it feeds your plan.

4. **Slice + plan locally.** Pick the smallest slice that satisfies the requirement. Optional scratchpad at `.claude/plans/<short-kebab>.md` — your own use, gitignored, never commit.

5. **Implement TDD.** Failing test first. Append non-obvious decisions to the Uncertainty Log (in your scratchpad) as you go.

6. **Verify locally before push.** Run the project's typecheck, lint, and test commands. If runtime-affecting, boot the relevant stack and exercise the change. Quietly — no narration. If something genuinely can't be verified, it becomes an Uncertainty Log entry: *"couldn't verify X because Y"*.

7. **Self-reflect silently before push.** Three questions: still solving the original ask? simplest thing that works? anything the human must know that isn't already in the Uncertainty Log? Clean → push. Flagged → fix it, or surface it as an Uncertainty Log entry. **Never** render a self-reflection block in the PR body.

8. **Push.** Commit with the project's conventional-commit format.

9. **Open the draft PR.** Body shape below. This is the first human surface — make it cheap to read.

10. **Run `/post-push`.** This is enforced — a Stop hook blocks the turn if you pushed and didn't invoke it. `/post-push` ensures the PR exists, schedules the single recurring `/babysit-pr <PR>` cron (idempotent — checks the cron list first), and spawns `/review` + `/diagnose` as parallel subagents. The babysit cron is the single source of truth for recurrence; do not schedule a competing one here.

11. **On merge.** Prune the worktree.

## PR body shape

```markdown
## What this changes
One paragraph in plain English. What the user sees, what behaviour
changes, what acceptance criteria it claims to satisfy.

## Uncertainty Log
- D-01: <one-line decision>. Why this, not the alternative. How to flip it.
- D-02: ...
```

That's it. No "What I tested" — successful verification is implicit. No self-reflection block. Three to five entries max; if you have more, you're flagging too eagerly. Omit the Uncertainty Log section entirely if nothing's non-obvious.

## Guardrails

- **Never merge** — human only.
- **Never push to `main` directly.** Always via PR.
- **Never force-push shared branches.**
- **Verification is non-negotiable.** No push without typecheck + lint + test green (or an Uncertainty Log entry explaining why a check is unrunnable).
- **Don't ask mid-task.** Pick, log it, let the human push back on the diff.
