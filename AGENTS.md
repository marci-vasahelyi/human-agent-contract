# AGENTS.md

## Agent/Human Contract

**Core principle.** The human's attention is the scarce resource. Agent compute is free. Optimise for: agents go wild producing and verifying; the human spends attention only at high-leverage moments. Many agents run in parallel — each one should cost the human almost nothing until it really has to.

**Implementation mandate.** Research, slice, implement, **verify locally**, push, open a draft PR with a working slice. The draft PR is the one human surface. Don't ask mid-task questions about scope or approach — pick, log it as an Uncertainty Log entry, let the human push back on the diff. Worst case they say "start over" — still cheaper than asking.

**Verification is non-negotiable.** Before any push: run the project's typecheck, lint, and test commands. For runtime-affecting changes, boot the relevant stack and exercise the flow. Quietly. If you genuinely can't verify something, that becomes an Uncertainty Log entry on the PR.

**After every push, run `/post-push`.** Enforced, not advised. A Stop hook should deterministically block the turn if a `git push` happened with no subsequent `/post-push` — the agent must not be able to quietly skip it. `/post-push` ensures a PR exists, ensures a single recurring `/babysit-pr` loop is scheduled for that PR (idempotent — check the cron list before adding), and spawns `/review` + `/diagnose` as parallel subagents on every push. Silent when clean. `/babysit-pr` should not self-schedule — competing crons are how this workflow rots.

**Two operating modes — cooperative is the default; autonomous is opt-in.**

- **Cooperative mode** is silent. Only structural guardrails fire (force-push block, plans-folder protection, destructive-op block). The human is in the loop turn-by-turn; the agent asks before non-trivial decisions, doesn't push without confirmation, no Uncertainty Log workflow.
- **Autonomous mode** turns on the decide-don't-ask contract above: prefer decisions over questions, log non-obvious calls to `.claude/uncertainties/<topic>.md`, push without confirmation when verified, run `/post-push` after every push (enforced). The worktree guard, push reminder, and Stop checklists all engage.

Mode is per-checkout (`.claude/.autonomous` = `on`/`off`) with optional per-session override (`.claude/.autonomous.d/<session_id>`). First session in a fresh checkout asks once and persists the answer. Toggle later with `/mode on|off|session on|session off|session clear|reset`. Mode-switch takes effect on the next turn — hooks re-read state on every fire.

**Bias toward fitting work into what's already there.** Before adding a new file, module, or abstraction, ask: *"would this fit in ~30 lines in files I already touched?"* If yes, do that. Three similar lines beat a premature abstraction. New surface area costs the human more attention to review than a slightly less elegant local change.

**There is no such thing as a "pre-existing failure."** CI passes on main. If CI fails on your branch, either your change broke it or your local setup is stale — investigate both. Never write "these are pre-existing", "existed on main too", or "not caused by my changes" as justification for stopping. Fix it or escalate with a specific reason.

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
3. Destructive git ops (force push, reset --hard on shared branches, remote branch deletion).
4. File-modifying work outside a worktree (when worktree workflow is in use).
5. Spending money / paid APIs not already wired.

**Flag workflow flaws — fix them inline when cheap.** If a skill, hook, or contract rule produces wrong/surprising behaviour, prefer a one-line fix on the current PR over filing follow-up work. Mention it briefly at the **top** of your reply: *"`/foo` did X; fixed inline in `abc1234`."* Only escalate to a separate change when the fix is too big or genuinely needs its own PR.

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
