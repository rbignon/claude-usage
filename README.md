# claude-usage

Fetch Claude usage stats (weekly quotas, global and per model) from claude.ai, with i3status bar integration and service status monitoring.

## Requirements

- Firefox with an active claude.ai session
- `sqlite3`, `curl`, `jq`, `bc`

## Setup

1. Copy `claude-usage` to your PATH (e.g. `~/.local/bin/`)
2. Set the `CLAUDE_ORG_ID` environment variable to your organization ID from claude.ai (visible in network requests to `/api/organizations/*/usage`)

## Usage

```bash
# Human-readable format
claude-usage
# Week:     47%  (resets 2026-11-23)
# Fable:    58%  (resets 2026-11-23)

# Raw JSON from API
claude-usage --json

# Compact format for statusbars: one LABEL|TEXT|PCT line per limit
claude-usage --statusbar
# |████▊░░░░░ 47% 1d 19h|47
# Fable|█████▊░░░░ 58% 1d 19h|58

# Claude Code service status from status.claude.com
claude-usage --status
# operational

# Latest benchmark score from isclaudedumb.today
claude-usage --bench
# 92.7
```

## i3status integration

`i3/claude-usage.sh` wraps `claude-usage` with caching and outputs i3bar-compatible JSON blocks.

### Output

JSON blocks prepended to your i3status bar: two indicators, then one block per usage limit reported by the API.

| Block | Description | Colors |
|-------|-------------|--------|
| `▲` / `▼` | Benchmark score (isclaudedumb.today) | `▲` green >= 90%, `▼` yellow >= 80%, `▼` red < 80%, gray = unknown |
| `●` | Claude Code service status | green = operational, yellow = degraded, orange = partial outage, red = major outage, blue = maintenance, gray = unknown |
| `████░░ 47% 1d 19h` | Weekly usage, all models (7-day window) | green < 70%, yellow >= 70%, red >= 90% |
| `Fable █████░ 58% 1d 19h` | Weekly usage of a per-model quota, prefixed with the model name (one block per quota) | same thresholds |

A single gray `--` block replaces the usage blocks when no usage data is available.

### Cache

Three independent caches to minimize API calls:

| Cache | TTL | File |
|-------|-----|------|
| Benchmark score | 900s | `/tmp/claude-bench-cache` |
| Service status | 60s | `/tmp/claude-status-cache` |
| Usage data | 300s | `/tmp/claude-usage-cache` |

All three fall back to stale cached values on fetch failure.

### i3 configuration

Copy `i3/claude-usage.sh` to `~/.i3/` and set your i3 `status_command` to a wrapper script:

```bash
#!/bin/bash
export CLAUDE_ORG_ID="your-org-id-here"

i3status | (read line && echo $line && read line && echo $line && while :
do
  read line
  claude_blocks=$(~/.i3/claude-usage.sh)
  echo "${line/[/[$claude_blocks,}" || exit 1
done)
```
