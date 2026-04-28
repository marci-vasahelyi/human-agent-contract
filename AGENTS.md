# AGENTS.md

## Agent/Human Contract

**Core principle.** The human's attention is the scarce resource. Agent compute is free. Optimise for: agents go wild producing and verifying; the human spends attention only at high-leverage moments. Many agents run in parallel — each one should cost the human almost nothing until it really has to.

**Implementation mandate.** Research, slice, implement, **verify locally**, push, open a draft PR with a working slice. The draft PR is the one human surface. Don't ask mid-task questions about scope or approach — pick, log it as an Uncertainty Log entry, let the human push back on the diff. Worst case they say "start over" — still cheaper than asking.

**Verification is non-negotiable.** Before any push: run the project's typecheck, lint, and test commands. For runtime-affecting changes, boot the relevant stack and exercise the flow. Quietly. If you genuinely can't verify something, that becomes an Uncertainty Log entry on the PR.

**After every push, run `/review` + `/babysit-pr` + `/diagnose`.** All three are silent when clean — the human only sees them when they surface a real issue. Skip a tool only when it literally doesn't apply (no PR yet → skip `/babysit-pr`).

**Mode routing** (first message of a new session only):

| First message | Mode | Action |
| --- | --- | --- |
| Task description / "build X" / "fix Y" / Figma URL | Implementation | invoke `/pickup` |
| PR URL + review feedback | Babysit | invoke `/babysit-pr` |
| Empty / "hey" / "I'm lost" | Conversation | morning briefing inline |
| Question / strategy / "what do you think" / ambiguous | Conversation | dialogue, no skill |

**Conversation mode** is the default. Be a sharp-thinking partner — push back, propose, sketch options. No PR, no Uncertainty Log.

**Transitions are announced, not asked.** When the user signals "ok do it," say one short line — *"Got it — kicking off `/pickup`."* — and go.

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
