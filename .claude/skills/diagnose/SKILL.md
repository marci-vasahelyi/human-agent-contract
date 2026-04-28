---
name: diagnose
description: 5-question trajectory check — am I solving the right problem, the simplest way, and is there anything the human MUST know right now? Fires post-commit/push automatically and on-demand when stuck or returning mid-task.
metadata:
  tags: reflection, accountability, trajectory, workflow
---

## What this is

`/diagnose` is the agent's accountability buddy. It runs five fixed questions, reports either *"on track"* or *"flagging X"*, and gets back to work. Stripped to the essentials — no investigation, no repair commands, no state reconciliation. Just the questions.

## When it fires

- **Automatically post-commit/push** during `/pickup` and `/babysit-pr`. After any push, run `/diagnose` silently before continuing the loop.
- **On-demand** via `/diagnose` whenever the agent or user thinks the agent might have drifted (long babysit loop, unclear next step, returning to a worktree mid-week).
- **Before surfacing to the human** — opening a draft PR, replying mid-loop, etc. Already implied by the pre-human-surface rule in AGENTS.md, but `/diagnose` is the structured form.

## The 5 questions

Answer each in **one sentence**. If all five answers are clean, output `On track.` and stop. If any answer surfaces drift, scope creep, simpler-alternative, or human-must-know, output `Flagging:` followed by the specific item(s).

1. **What is the original ask?** (requirement / first message — quote it briefly)
2. **What am I doing right now?** (current scope of work in the worktree — diff summary in one line)
3. **Is there drift?** (does (2) still solve (1) — yes / no, why)
4. **Is this the simplest solution that works?** (or am I over-engineering — yes / no, what would be simpler)
5. **Is there anything the human MUST know about right now?** (blockers, scope changes, hard boundaries hit, surprising findings, decisions that should be in the Uncertainty Log but aren't)

## Output shape

**Clean (on track):**
```
🪞 /diagnose — On track.
```

**Drift detected:**
```
🪞 /diagnose — Flagging:
- Q3 (drift): expanded from "fix login redirect" to "refactor auth middleware" — adding 6 unrelated files. Pulling back to original scope.
- Q5 (must-know): hard boundary almost hit — would have force-pushed shared branch in step 8. Aborted, will use safe rewrite.
```

If anything surfaces under Q5 that's a hard boundary or a real workflow flaw, follow the rules in `AGENTS.md` (announce in ⚠️ block at top of next reply / fix inline when cheap).

## Rules

- **Five questions, fixed list.** No expanding the questionnaire. If the questions don't catch a problem, that's a contract debt to address, not a reason to add more questions inline.
- **One sentence per answer.** No paragraphs. If you can't answer in one sentence, that's itself a signal of drift.
- **Silent when clean.** Post-commit `/diagnose` doesn't generate noise unless something's flagged. The user shouldn't see `On track.` over and over.
- **Loud when not.** Drift gets flagged in the next reply, top of message, ⚠️ block. No burying.
