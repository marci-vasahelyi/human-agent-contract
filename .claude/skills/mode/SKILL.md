---
name: mode
description: Show or switch the AI workflow mode (cooperative ↔ autonomous), globally for this checkout or per-session. Trigger when the user wants to change how the agent behaves — including plain-English requests like "switch to autonomous mode" or "go cooperative for this session".
metadata:
  tags: workflow, mode
---

## What this is

A friendly wrapper for the cooperative/autonomous mode files described in `AGENTS.md`. Users should never have to type `echo on > .claude/.autonomous.d/<uuid>` themselves.

Treat plain-English mode requests as equivalent to the matching `/mode` form — *"switch to autonomous"* → `/mode on`, *"just this session"* → `/mode session on`.

## State model

Two files control the mode (both gitignored):

- `.claude/.autonomous` — **global default** for this checkout (`on` or `off`)
- `.claude/.autonomous.d/<session_id>` — **per-session override** (`on` or `off`)

Effective mode for a given session: override-file wins; otherwise global default wins. If neither exists, the SessionStart picker fires on the next session.

Per-session override files should be deleted automatically by a `SessionEnd` hook — no stale files.

## Usage

| Form | Effect |
|------|--------|
| `/mode` | Print current effective mode + global default + this-session override (if any) |
| `/mode on` | Set **global** default to autonomous |
| `/mode off` | Set **global** default to cooperative |
| `/mode session on` | Override **this session only** to autonomous (global unchanged) |
| `/mode session off` | Override **this session only** to cooperative (global unchanged) |
| `/mode session clear` | Drop this session's override; fall back to global |
| `/mode reset` | Delete the global file (next session re-prompts via first-run picker) |

## Flow

1. Parse the argument. If empty → status mode.
2. For any `session …` form, derive the session id from `$CLAUDE_CODE_SESSION_ID`. If empty, fail loudly — per-session overrides depend on it.
3. Run the matching bash command:
   - `on` → `mkdir -p .claude && echo on > .claude/.autonomous`
   - `off` → `mkdir -p .claude && echo off > .claude/.autonomous`
   - `session on` → `mkdir -p .claude/.autonomous.d && echo on > ".claude/.autonomous.d/$CLAUDE_CODE_SESSION_ID"`
   - `session off` → `mkdir -p .claude/.autonomous.d && echo off > ".claude/.autonomous.d/$CLAUDE_CODE_SESSION_ID"`
   - `session clear` → `rm -f ".claude/.autonomous.d/$CLAUDE_CODE_SESSION_ID"`
   - `reset` → `rm -f .claude/.autonomous`
4. Confirm to the user in one line: current effective mode + (if per-session override active) "(session override)".

## Rules

- The agent must not invent its own session id. Use `$CLAUDE_CODE_SESSION_ID` (set by Claude Code) — if absent, surface the error rather than guessing.
- Hooks should re-read state on every fire; no restart needed after switching.
- Mode-switch mid-session takes effect on the next turn. If you switched from autonomous → cooperative, prior autonomous-contract priming no longer applies.
