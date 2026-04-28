# Third-Party Library Check

## When to use

Use this skill **proactively** before recommending or installing any third-party package. Also use when the user asks to evaluate a library.

Trigger on:
- `npm install`, `yarn add`, `pip install`, `cargo add`, etc. suggestions
- "should we use X library?"
- "is there a package for Y?"
- Any recommendation that involves adding a dependency

## Checklist

For every library, verify ALL of these via web search:

### 1. Maintenance (deal-breaker)

- **Last commit**: < 6 months = active, 6-12 months = caution, > 1 year = avoid
- **Last release**: Check the package registry's publish date
- **Open issues vs closed ratio**: High open/low closed = red flag
- **Deprecated/archived**: Check GitHub repo banner and README

### 2. Popularity & Trust

- **Weekly downloads**: Compare against alternatives
- **GitHub stars**: Relative to category
- **Used by**: Check "Used by" count on GitHub — real adoption signal
- **Maintainer**: Solo dev vs org/team

### 3. Compatibility

- **Language/runtime version**: Check against the project's version
- **Platform**: Does it run where it needs to (server, browser, mobile, edge)?
- **Build/bundler**: Does it work with the project's build setup?

### 4. Security

- **Vulnerability scanners** (Snyk, `npm audit`, OSV, etc.): Known vulnerabilities?
- **Dependencies**: How many transitive deps? Heavy dependency trees = risk
- **Bundle size** (for client-side): Check bundlephobia.com or equivalent impact

### 5. Alternatives (always check)

- Is there a **built-in / stdlib** solution?
- Is there an **established framework module** that does this?
- Are there **2-3 competing libraries**? Compare them side-by-side
- [IMPORTANT] Can this be done with **50 lines of code** instead of a dependency?

## Output format

Present findings as a compact table:

```text
| Criteria | <lib-name> | <alternative> |
|----------|-----------|---------------|
| Last commit | 2024-01 | 2026-03 |
| Weekly downloads | 5k | 200k |
| Compatible | No | Yes |
| Bundle size | 45kb | 12kb |
| Verdict | CAUTION: stale (6-12mo) | RECOMMENDED |
```

Verdict tiers: `RECOMMENDED` / `CAUTION: <reason>` (6–12 months inactive, few maintainers, etc.) / `AVOID: <reason>` (>1 year inactive, deprecated, security issues).

## Rules

- **Never recommend a library without checking maintenance first**
- **Always present at least one alternative** (even if it's "build it yourself")
- **Built-in solutions beat third-party** — if the stdlib or framework has it, use it
- **Unmaintained = no** — no matter how many stars or how popular it was
- **When in doubt, fewer dependencies wins** — a 50-line utility > a package with 20 transitive deps
