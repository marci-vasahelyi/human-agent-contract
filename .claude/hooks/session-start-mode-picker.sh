#!/usr/bin/env bash
# SessionStart hook: if the global mode file doesn't exist, inject a
# first-run picker instruction so the agent asks the user to pick a
# default (cooperative or autonomous).
set -u
[ -f "${CLAUDE_PROJECT_DIR:-.}/.claude/.autonomous" ] && exit 0

jq -cn --arg ctx "FIRST-RUN MODE PICK REQUIRED. The file .claude/.autonomous does not exist, which means this developer has not yet chosen a default AI workflow mode. BEFORE responding to ANY user prompt this session, the agent's FIRST action MUST be to ask the user via interactive picker (or plain question): pick the default for this checkout — (1) Cooperative: agent stays interactive and asks before non-trivial decisions [persists off]. (2) Autonomous: agent decides low-stakes calls on its own, logs uncertainties, surfaces only at checkpoints [persists on]. Mention that they can override per-session anytime with /mode session on or /mode session off (or just tell the agent in plain English, e.g. \"switch to autonomous for this session\"). Then run via Bash exactly one of: echo off > .claude/.autonomous / echo on > .claude/.autonomous. Only after the file exists, proceed with the user prompt." \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
