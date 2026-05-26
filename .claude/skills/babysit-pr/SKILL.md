---
name: babysit-pr
description: Monitor a PR until CI is green and all review comments are resolved. Autonomous triage and fix; only surfaces to the human for genuinely ambiguous cases, scope-expanding fixes, or stuck CI. Loops until clean.
metadata:
  tags: pr, ci, review, github, automation
---

## When to use

Invoke with `/babysit-pr` or `/babysit-pr <PR number>`. Use when:
- A PR was just created and you want CI + comments handled automatically
- CI failed and you want the agent to fix it
- Review comments came in and need triage + fixing
- The user says "make the PR green" or "handle PR feedback"

If no PR number is given, use the current branch's open PR.

## Core behaviour — autonomous, not per-fix

Per the Agent/Human Contract in `AGENTS.md`: the human's cognitive capacity is the scarce resource. Do not interrupt for every comment. Triage, fix, reply, resolve — by yourself. Only surface when genuinely needed, and when you do, batch everything into one message framed as concrete choices ("A or B?"), not open-ended ("what do you think?").

**Keep looping until the PR is truly clean.** Exit only when: CI green + 0 unresolved threads + no merge conflicts + review not blocking.

## There is no such thing as a "pre-existing failure"

CI passes on main. If CI fails on your branch, either your change broke it or your local setup is stale. Investigate both. **Never** write "these are pre-existing", "existed on main too", or "not caused by my changes" as justification for stopping. Fix it or escalate to the user with a specific reason — not a hand-wave.

## Subagent return protocol

Any parallel subagent you spawn (the first-iteration triad, delegated research, anything multi-step) must return a typed status as the first line per the protocol in `AGENTS.md` — `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, or `BLOCKED`. Include the addendum in every brief. Free-form prose makes the controller guess intent.

**Keep looping until the PR is truly clean.** Exit only when: CI green + 0 unresolved threads + no conflicts + `reviewDecision` not blocking (APPROVED, `null`, or a stale bot review you've pinged/surfaced). Don't exit after one pass. Don't walk off to other work while comments are open.

## Loop

This skill runs in a **loop until the PR is fully green**. Each iteration:

### 1. Get PR number
```
gh pr view --json number -q .number
```
Or use the number passed as argument.

### 2. Check CI status
```
gh pr checks <PR>
```
If all checks pass and no unresolved comments → done. Tell the user with a ready-to-merge summary (see "Exit" below).

### 3. Check for merge conflicts

`gh pr view <PR> --json mergeable,mergeStateStatus`. If conflicting, merge base branch, resolve conflicts, commit, and push. This retriggers CI — loop back to step 2.

### 4. If CI failed — diagnose and fix

- Get failed job logs: `gh run view <run-id> --job <job-id> --log-failed`
- Fix the failure autonomously if the cause is clear. Commit, push, re-check.
- **External-only review tools** (e.g. SonarCloud dashboards) are the exception — the agent cannot access them. Batch as one ask and surface to the user.
- **Truly stuck on CI** (2 honest fix attempts fail, or the failure is infra/flaky/external): surface to user in the batched gate message.

### 5. Check review comments

```bash
gh api repos/{owner}/{repo}/pulls/<PR>/comments --jq '.[] | {id, path, body, user: .user.login}'
gh api repos/{owner}/{repo}/pulls/<PR>/reviews --jq '.[] | select(.state != "APPROVED") | {id, body, user: .user.login, state}'
```

### 6. Triage autonomously, post a visible classification

For each unresolved comment, classify **without asking the user**:

- **Fix & reply** — valid bug / real code smell / missing edge case / clearer naming. The common case. Fix it, commit, reply, resolve.
- **Push back & reply** — false positive, stylistic nit that contradicts project conventions (check `AGENTS.md`), or already handled elsewhere. Reply explaining why, resolve the thread.
- **Defer (out of scope)** — genuine improvement but expands the PR beyond its original scope. Scope-expansion indicators: touching files unrelated to the task, adding dependencies not in the plan, changing public APIs beyond the PR's stated intent. Reply noting it as out of scope and resolve, or open a follow-up issue if the project tracks them.
- **Surface at gate** — genuinely ambiguous intent the agent can't resolve from context. Do NOT fix yet. Add to the batched gate message for the user.

**Before fixing anything, post a single PR comment with the full triage** so the reviewer can see what's in scope vs deferred vs pushed-back without chasing per-thread replies. Format:

```markdown
## Triage of this review pass

| # | Comment | Classification | Action |
| --- | --- | --- | --- |
| 1 | "rename Fetcher to Loader" | Push back | Reply — matches `useFetcher` already in codebase |
| 2 | "missing null check in payment.service.ts:42" | Fix & reply | TDD fix incoming |
| 3 | "also migrate legacy auth middleware" | Defer | Out of scope, will reply-and-resolve |
| 4 | "is this safe under concurrent writes?" | Surface at gate | Real ambiguity — needs the human's call |

Proceeding with fixes for item 2. Items 1 and 3 will get reply-and-resolve. Item 4 will appear in the batched gate message.
```

This is the **primary** mid-loop audit trail for the reviewer. The batched gate message in step 9 only fires when there are genuinely ambiguous items the agent can't resolve. Then proceed with fixes.

### 7. Fix the "fix & reply" bucket

- **TDD still applies** (per `AGENTS.md`). When a review comment exposes a bug or missing edge case, write a failing test that reproduces it *before* the fix. For doc-only or style-only comments, skip the test — nothing to assert on.
- Apply the fixes
- Run the project's typecheck, lint, and test commands locally before committing
- Commit using the project's conventional-commit format. Include review comment IDs in the commit body when useful.
- Push

### 8. Reply + resolve threads

For **every** comment you addressed (whether you fixed or pushed back):

```bash
# Reply explaining the resolution
gh api repos/{owner}/{repo}/pulls/<PR>/comments/<comment_id>/replies \
  -f body="Fixed: <what changed>" \
  # or -f body="No change: <why — reference convention or existing code>"

# Get thread IDs
gh api graphql -f query='query { repository(owner:"<owner>", name:"<repo>") { pullRequest(number:<PR>) { reviewThreads(first:100) { nodes { id isResolved comments(first:1) { nodes { body path } } } } } } }'

# Resolve the thread AFTER replying
gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "<thread_id>"}) { thread { isResolved } } }'
```

**Never resolve without replying.** The reply lets the reviewer verify the fix without re-reading the diff.

### 9. Batched gate message (only if genuinely needed)

If after step 6 there are items in the "surface at gate" bucket, or CI is genuinely stuck (step 4), surface **once** with everything bundled. Use A/B framing:

> Three items need your call before I can continue:
>
> 1. **#28 (PR comment):** reviewer asks to rename `Fetcher` → `Loader`. Two options: (A) rename (widens diff to ~12 files, low risk); (B) push back — `Fetcher` matches `useFetcher` already in the codebase. Which?
> 2. **#31 (scope):** reviewer asks to also migrate the legacy auth middleware. That's separate scope. (A) do it here; (B) push back as out of scope.
> 3. **CI:** SonarCloud reporting 2 new code smells on `payment.service.ts`. Dashboard only — can you paste them here so I can fix?

Then stop and wait for the user's reply. When they respond, apply decisions and resume the loop.

### 10. Return — do not self-schedule

After one pass (CI poll + triage + any fix push), return. The recurring `/loop <interval> /babysit-pr <PR>` cron created by `/post-push` will fire again on its next interval. **Do not self-schedule from inside babysit** — that creates competing crons that quietly multiply.

If babysit was triggered manually (no `/post-push` cron exists) and the PR is not clean yet, surface that to the user explicitly — they can re-run `/post-push` to start the cron, or invoke `/babysit-pr` again manually. Do not silently hand back.

When the cron fires again, re-poll **both** CI and review comments — reviewers (especially bots like coderabbitai) frequently leave new comments after a fix push. Do not declare the PR clean from CI alone.

## Exit — ready-to-merge summary

When all CI passes, no unresolved comments, no conflicts: before telling the user "done," ensure the PR description is in its final two-section shape per `/implement` (*What this changes* + *Uncertainty Log*). Trim or remove Uncertainty Log entries that are no longer load-bearing.

Then one short message to the user:
> "PR #XXX is clean — CI green, N reviewers approved. Ready for merge."

Do not merge — human-only boundary. Let them merge.

## Rules

- **Autonomous by default** — only surface for genuinely ambiguous comments, scope expansion, or stuck CI
- **Always reply before resolving** — reviewers need to verify without re-reading
- **Always check for merge conflicts** — green CI with conflicts still blocks merge
- **Batch gate messages** — one message with all outstanding items in A/B framing, never per-comment
- **The user can't self-approve.** "Waiting on reviewer" ≠ "waiting on user." If a bot left `CHANGES_REQUESTED` and all its threads are resolved, that's stale — ping the bot for a fresh review. If it stays stale, batch it as one A/B ask (dismiss vs. wait). Don't just stop and hand back.
