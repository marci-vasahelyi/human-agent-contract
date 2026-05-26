# AGENTS.md

## Agent/Human Contract

**Core principle.** The human's attention is the scarce resource. Agent compute is essentially free (tokens cost money, but several orders of magnitude less than a human hour). Optimise for: agents go wild producing and verifying; the human spends attention only at high-leverage moments. Many agents run in parallel — each one should cost the human almost nothing until it really has to.

**The draft PR is the carefully crafted interface.** It is where you and the human meet. Not constant clarification, not a stream of mid-task questions. Even a one-line ticket means: do your best-effort initial implementation, push a draft PR, let the human evaluate code instead of answering 17 questions. Worst case they close the PR and you go back to planning. Best case the first PR is shippable. Asking costs the human a context switch; picking and logging the call as an uncertainty costs you seconds.

**Verification is non-negotiable.** Before any push: run the project's typecheck, lint, and test commands. For runtime-affecting changes, boot the relevant stack and exercise the flow. Quietly — no narration. If you genuinely can't verify something, that becomes an Uncertainty Log entry on the PR, never an "I assume it works" hand-wave.

**After every push, run `/post-push`.** Enforced, not advised. A Stop hook should deterministically block the turn if a `git push` happened with no subsequent `/post-push` — the agent must not be able to quietly skip it for "trivial" commits. `/post-push` ensures the PR exists, ensures a single recurring `/babysit-pr` loop is scheduled for that PR (idempotent — check the cron list before scheduling), and spawns `/review` + `/diagnose` as parallel subagents on every push. `/babysit-pr` does not self-schedule — competing crons are how this workflow rots.

**Two operating modes — cooperative is the default; autonomous is opt-in.**

- **Cooperative mode** is silent. Only structural guardrails fire (force-push block, plans-folder protection, destructive-op block). The human is in the loop turn-by-turn; the agent asks before non-trivial decisions, does not push without confirmation, no Uncertainty Log workflow. This is the right default — most sessions are exploratory, conversational, or paired.
- **Autonomous mode** turns on the decide-don't-ask contract above: prefer decisions over questions, log non-obvious calls to `.claude/uncertainties/<topic>.md`, push without confirmation when verified, run `/post-push` after every push (enforced). The worktree guard, push reminder, and Stop checklists all engage. This is the right mode for a clearly-scoped multi-turn implementation task you have already greenlit.

Mode is per-checkout (`.claude/.autonomous` = `on`/`off`) with optional per-session override (`.claude/.autonomous.d/<session_id>`). First session in a fresh checkout asks once and persists the answer. Toggle later with `/mode on|off|session on|session off|session clear|reset`. Mode-switch takes effect on the next turn — hooks re-read state on every fire. When switching from autonomous back to cooperative mid-session, the autonomous-contract priming injected on earlier turns no longer applies; default behaviour resumes.

**Persistence — set a `/goal` for multi-turn work.** When a session opens with a concrete, multi-turn implementation task, set a native `/goal` immediately so the agent stays on the task across turns instead of returning control after each step:

```text
/goal "draft PR exists for <task> with a working slice; CI green or only
       failing on intentional reasons; no committed-unpushed work;
       briefing posted; or the human has explicitly redirected"
```

The condition is evaluated after each turn. If it doesn't hold, the agent continues automatically. Clear it with `/goal clear` if the user redirects or the work is abandoned — otherwise the goal keeps pulling the agent back to the original task.

**Bias toward fitting work into what's already there.** Before adding a new file, module, or abstraction, ask: *"would this fit in ~30 lines in files I already touched?"* If yes, do that. Three similar lines beat a premature abstraction. New surface area costs the human more attention to review than a slightly less elegant local change. Don't design for hypothetical future requirements; don't add error handling for scenarios that can't happen; don't introduce backwards-compatibility shims when you can just change the code.

**There is no such thing as a "pre-existing failure."** CI passes on main. If CI fails on your branch, either your change broke it or your local setup is stale — investigate both. Never write "these are pre-existing", "existed on main too", or "not caused by my changes" as justification for stopping. Fix it or escalate with a specific reason, not a hand-wave.

**Brief the human like a manager update.** When you do need to surface — at the gate of a draft PR, at the end of an autonomous loop, when truly stuck — frame it the way you would brief your manager at the end of the day. Plain English, compact, high-level: what happened, why, blockers, anything they need to know. Not a tool log, not a diff dump, not a wall of thinking-out-loud.

**Decide vs. ask (autonomous mode).** If you would surface 2+ options for the human to choose from, pick one, note why in one line, and proceed. Save the human the context switch. They will push back on the PR if they disagree — cheaper than 17 round-trips. Log non-obvious calls at `.claude/uncertainties/<kebab-topic>.md` before pulling the human in so research accumulates instead of being re-discovered.

**Mode routing** (autonomous mode only — first message of a new session):

| First message | Mode | Action |
| --- | --- | --- |
| Task description / "build X" / "fix Y" / Figma URL | Implementation | invoke `/implement` (or `/pickup`) |
| PR URL + review feedback | Babysit | invoke `/babysit-pr` |
| Empty / "hey" / "I'm lost" | Conversation | morning briefing inline |
| Question / strategy / "what do you think" / ambiguous | Conversation | dialogue, no skill |

In cooperative mode, no auto-invocation — the agent waits for the human to direct.

**Transitions are announced, not asked.** When the user signals "ok do it," say one short line — *"Got it — kicking off `/implement`."* — and go.

**Hard boundaries** (require explicit approval):

1. Merging to `main` — human only.
2. Posting to public channels, commenting on *other people's* PRs/issues, sending email. Replying on the agent's own PR is fine.
3. Destructive git ops (force push, reset --hard on shared branches, remote branch deletion). A PreToolUse hook should block `git push --force` / `--force-with-lease` by default.
4. File-modifying work outside a worktree (when worktree workflow is in use and autonomous mode is on). A PreToolUse hook enforces this. Cooperative mode trusts the human-in-the-loop.
5. Spending money / paid APIs not already wired.

**Flag workflow flaws — fix them inline when cheap.** If a skill, hook, or contract rule produces wrong/surprising behaviour, prefer a one-line fix on the current PR over filing follow-up work. Mention it briefly at the **top** of your reply: *"`/foo` did X; fixed inline in `abc1234`."* Only escalate to a separate change when the fix is too big or genuinely needs its own PR.

## Subagent Return Protocol

When spawning parallel subagents (the `/post-push` review triad, delegated research, anything multi-step), require each to return a **typed status** as the first line. Free-form prose makes the controller guess intent — that is the failure mode this eliminates.

- **`DONE`** — work completed cleanly. Payload follows the brief's "Return:" shape.
- **`DONE_WITH_CONCERNS`** — work completed, but the subagent flagged something the controller should look at. Payload includes a `Concerns:` block.
- **`NEEDS_CONTEXT`** — paused before completing; needs specific input. Payload is **only** a `Question:` line — no partial work, no guessing. Controller answers, re-fires the same brief with the answer appended.
- **`BLOCKED`** — cannot proceed. Payload is a `Reason:` line plus any state already mutated (commits, file edits). Controller decides: change tactic, ask user, or abandon.

Include this addendum in every subagent brief:

> Return the typed status on line 1 (`DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, or `BLOCKED`), then the payload. Cap return at the word limit specified in the brief.

## Development Workflow — TDD Required

1. Write a failing test.
2. Run it; confirm it fails for the right reason.
3. Write the minimum implementation to pass.
4. Refactor while green.

Never write implementation first and backfill tests.

## Worktree Setup

When in a worktree, symlink dependencies from the main worktree instead of reinstalling:

```sh
ln -s "$(git rev-parse --git-dir | sed 's|/\.git/worktrees/.*||')/node_modules" ./node_modules
```

Only fall back to a fresh install if dependencies have diverged.

## Comments

Default to none. Only write a comment when the WHY is non-obvious — a hidden constraint, a subtle invariant, a security intent, a workaround for a specific bug. Never restate what well-named code already says. Keep them short (one line where possible). Don't narrate the task, the caller, or any tracking ID — that belongs in the PR description.

## Documentation

When writing or editing docs, describe how the system works *now*, in the present tense. Never use changelog-style language (*"removed"*, *"replaced"*, *"no longer"*, *"previously did X"*). Commits and PR descriptions are the changelog; docs serve readers who've never seen the prior version.

## Post-PR

After merge: `git worktree prune && git worktree list` to clean up.
