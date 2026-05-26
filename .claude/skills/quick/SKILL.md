---
name: quick
description: Explicit escape hatch for trivial one-line fixes (typo, dep bump, config tweak, comment fix). Skips plan / Gate 1 / Uncertainty Log ceremony — goes straight to a non-draft PR. Use only when the change really is one obvious line, not as a shortcut around the regular flow.
metadata:
  tags: workflow, fast-path, trivial
---

## What this is

`/quick "<one-liner description>"` is the explicit escape hatch for changes that genuinely don't need the gate ceremony — a typo fix, a dep bump that the bot already validated, a `.env.example` tweak, a comment correction. **The point is to make the bypass explicit and named, so the contract isn't silently shortcut when it doesn't fit.**

## When to use it (and when NOT to)

**Use `/quick` when:**
- Single-file, single-line (or very-few-line) change
- Zero design judgment — the right fix is obvious
- No new behavior — purely cosmetic, doc, or mechanical
- A reviewer would never ask "why did you do it this way?"

**Do NOT use `/quick` when:**
- Multiple files touched
- Any architectural decision involved
- New code paths or new behavior
- Any review-comment-shaped uncertainty
- "Bug fix" of any non-trivial kind — those need `/pickup` so the Uncertainty Log captures the call

If unsure, use `/pickup`. The cost of using `/pickup` for a trivial fix is one extra commit; the cost of using `/quick` for a non-trivial fix is silent drift.

## Flow

1. **Branch from latest `main`** in a worktree (`/quick-<short-kebab>`).
2. **Make the one-line change.** Run the project's typecheck, lint, and test commands if the file is in a tested module.
3. **Commit + push** with a tight conventional-commit message (`type: description`).
4. **Open a non-draft PR** with a one-paragraph PR body: what changed, why. **No Uncertainty Log, no Self-reflection, no plan.**
5. **`/post-push` still applies** — the contract's pre-human-surface rule doesn't get bypassed by `/quick`. The Stop hook still enforces post-push, and `/post-push` runs `/review` + `/diagnose` and schedules `/babysit-pr`. Only the plan / Gate 1 / Uncertainty Log ceremony is skipped.
6. Tell the user one line: *"Quick PR open — [link]. One-line fix: <description>."*

## What's intentionally missing

- No draft phase / Gate 1.
- No Uncertainty Log (there are no decisions worth logging — that's the precondition for `/quick` being appropriate).
- No Self-reflection block (nothing to reflect on for a typo).

## Rules

- **`/quick` doesn't skip CI or `/post-push`.** The pre-human-surface rule from AGENTS.md still fires. CI green, `/review` clean, `/diagnose` clean — same bar as any other PR before merge. The shortcut is on *planning*, not *verification*.
- **If a `/quick` PR draws review comments that aren't trivial nits**, the original judgment was wrong — the change wasn't actually quick. Pivot to the `/babysit-pr` flow normally; don't try to defend the `/quick` framing.
- **Hard boundaries still apply.** No merging to `main` (human only). Same as ever.
