---
name: implement
description: Drive a task end-to-end to a draft PR with a working slice. Research, slice, implement, verify locally, push, open the PR — that is the first human surface. Auto-invoke when a new session opens with a task-shaped first message, or when a conversation transitions to "ok do it". Successor to `/pickup` — adds `/goal` persistence for multi-turn work.
metadata:
  tags: workflow, driver
---

## Persistence — set a `/goal` first

This skill is synchronous, multi-turn, end-to-end work. Before doing anything else, set a native `/goal` so the agent stays on task across turns instead of returning control after each step:

```text
/goal "draft PR exists for <task> with a working slice; CI green or only
       failing on intentional reasons; no committed-unpushed work;
       briefing posted; or the human has explicitly redirected"
```

The condition is evaluated after each turn. If it doesn't hold, the agent automatically continues to the next turn. Clear it with `/goal clear` if the user redirects or the work is abandoned — otherwise the goal will keep pulling the agent back to the original task.

## There is no such thing as a "pre-existing failure"

CI passes on main. If CI fails on your branch, either your change broke it or your local setup is stale. Investigate both. **Never** write "these are pre-existing", "existed on main too", or "not caused by my changes" as justification for stopping. Fix it or escalate to the user with a specific reason.

## Flow

1. **Identify the task.** Task description / branch name / issue link / Figma URL? Use it. Nothing obvious? Ask once: *"What do you want to implement?"*

2. **Set the `/goal`** (see above) — substitute the task into the condition.

3. **Worktree on latest main.** `git fetch origin main`, then `EnterWorktree` named after the task in kebab-case (e.g. `fix-login-redirect`, `add-drizzle-schema`). Symlink `node_modules` per AGENTS.md if applicable.

4. **Research.** Project docs first, then code. Web search for non-trivial libraries, specs, CVEs. Don't dump research at the user — it feeds your plan.

5. **Slice + plan locally.** Pick the smallest slice that satisfies the requirement. Optional scratchpad at `.claude/plans/<short-kebab>.md` — your own use, gitignored, never commit.

6. **Implement TDD.** Failing test first. Append non-obvious decisions to the Uncertainty Log (in your scratchpad) as you go.

7. **Verify locally before push.** Run the project's typecheck, lint, and test commands. If runtime-affecting, boot the relevant stack and exercise the change. Quietly — no narration. If something genuinely can't be verified, it becomes an Uncertainty Log entry: *"couldn't verify X because Y"*.

8. **Self-reflect silently before push.** Three questions: still solving the original ask? simplest thing that works? anything the human must know that isn't already in the Uncertainty Log? Clean → push. Flagged → fix it, or surface it as an Uncertainty Log entry. **Never** render a self-reflection block in the PR body.

9. **Push.** Commit with the project's conventional-commit format.

10. **Open the draft PR.** Body shape below. This is the first human surface — make it cheap to read.

11. **Run `/post-push`.** Enforced — a Stop hook blocks the turn if you skip it. `/post-push` ensures the PR exists, schedules the single recurring `/babysit-pr` cron (idempotent — checks the cron list first), and spawns `/review` + `/diagnose` as parallel subagents. The babysit cron is the single source of truth for recurrence; do not schedule a competing one here.

12. **On merge.** Brief the user the way you would brief your manager — plain English, compact, what shipped and why. Prune the worktree. `/goal` clears itself once its condition holds.

## PR body shape

```markdown
## What this changes
One paragraph in plain English. What the user sees, what behaviour
changes, what acceptance criteria it claims to satisfy.

## Uncertainty Log
- D-01: <one-line decision>. Why this, not the alternative. How to flip it.
- D-02: ...
```

Omit the Uncertainty Log section entirely if nothing is non-obvious.

## Guardrails

- **Never merge** — human only.
- **Never take over a PR you did not open** without asking the user first.
- **Never force-push without explicit authorization.** Even on your own branch, ask first. Prefer additive commits, revert commits, or a fresh PR over rewriting history.
- **Autonomous mode:** don't ask mid-task questions about scope, approach, or slicing — pick, log as uncertainty, let the human push back on the diff. **Cooperative mode:** surface non-trivial decisions to the user and ask before proceeding.
- **`.claude/plans/` is local.** Never `git add -f` it.
- **If the user redirects mid-task**, run `/goal clear` before pivoting — otherwise the goal will keep pulling you back to the original task.
