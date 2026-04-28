---
name: figma-extract
description: Extract Figma design specs from one or more Figma URLs and save actionable design docs
argument-hint: <figma-url-1> [figma-url-2] ...
allowed-tools: mcp__figma__get_design_context, mcp__figma__get_metadata, mcp__figma__get_screenshot, mcp__figma__get_variable_defs, Read, Write, Edit, Glob, Grep, Bash, ToolSearch
---

# Figma Design Extraction

Extract design specs from Figma URLs and produce actionable design spec documents.

## When to use

Use this skill **proactively** whenever Figma is involved:
- The user shares any Figma URL (figma.com/design/..., figma.com/board/...)
- The user mentions implementing a screen or component from Figma
- The user asks about design details, tokens, or layout from Figma
- Any task that references Figma designs as a source of truth

Always produce a design spec document as output — this is the standard workflow for translating Figma into implementation.

## Input

The user provides one or more Figma URLs as arguments: $ARGUMENTS

## Step 1: Validate MCP availability

Call `mcp__figma__get_metadata` with a known nodeId (`0:1`) and fileKey extracted from the first URL.

If the call fails with a connection or auth error, STOP and tell the user:

```
Figma MCP is not available. To fix:
1. Ensure you have the Figma MCP server configured
2. In VSCode: it should be auto-configured via the extension
3. In CLI: run `claude mcp add --transport http figma https://mcp.figma.com/mcp`
4. Restart your Claude Code session
```

## Step 2: Parse URLs

For each Figma URL, extract `fileKey` and `nodeId`:
- `figma.com/design/:fileKey/:fileName?node-id=:nodeId` → convert `-` to `:` in nodeId
- `figma.com/design/:fileKey/branch/:branchKey/:fileName` → use branchKey as fileKey

If a URL cannot be parsed, skip it and warn the user.

## Step 3: Fetch design data

**CRITICAL — Context window protection:**
- `get_metadata` on full files returns 500K+ chars and WILL blow up the context window. This has caused context loss in multiple sessions.
- NEVER call `get_metadata` on a full file (e.g. with just fileKey and `0:1`). Only use it on specific, narrow nodeIds for individual screens/components.
- Prefer `get_design_context` and `get_screenshot` with specific nodeIds — these are safe and return focused data.
- Extract findings and write to disk immediately. Do not rely on keeping large Figma responses in context memory.

For each parsed URL, call these in parallel:
1. `mcp__figma__get_design_context` with `clientFrameworks: "react"`, `clientLanguages: "typescript"` — returns reference code + screenshot
2. `mcp__figma__get_screenshot` — returns a visual of the specific node

Only call `mcp__figma__get_metadata` on **individual screen/component nodeIds**, never on file-level nodes.

If the design uses variables/tokens, also call `mcp__figma__get_variable_defs` to capture design tokens.

## Step 4: Create design spec document

For each screen, create a spec file at `docs/design-specs/<screen-name>.md` (use kebab-case, derive screen name from the Figma node name).

The spec must be **actionable** — a developer should be able to implement the screen from this doc alone. Use this format:

```markdown
# <Screen Name>

**Figma**: <original URL>
**Node**: `<nodeId>` | **File**: `<fileKey>`

## Layout

- Viewport / container sizing
- Key layout structure (flex direction, alignment, spacing)
- Background color/image

## Components

List each distinct UI element:
- Component name / type
- Position and size
- Content (text, icons, images)

## Typography

| Element | Font | Size | Weight | Line Height | Letter Spacing | Color |
|---------|------|------|--------|-------------|----------------|-------|

## Colors

| Usage | Value | Token (if available) |
|-------|-------|---------------------|

## Spacing & Sizing

Key spacing values, padding, margins, border radius.

## Interactive States

Buttons, inputs, toggles — their states (default, pressed, disabled, error).

## Notes

Any design annotations, constraints, or non-obvious details.
```

Omit any section that has no relevant data (e.g. skip "Interactive States" if there are none).

## Step 5: Summary

After creating all spec files, output a summary listing:
- Each screen name and its spec file path
- Any warnings (unparseable URLs, missing data)
- Any new colors or tokens not yet in `apps/mobile/src/theme/tokens.ts`
