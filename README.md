# claude-usage

Fetch Claude usage stats (session and weekly quotas) from claude.ai, with i3status bar integration and service status monitoring.

## Requirements

- Firefox with an active claude.ai session
- `sqlite3`, `curl`, `jq`

## Setup

1. Copy `claude-usage` to your PATH (e.g. `~/.local/bin/`)
2. Set the `CLAUDE_ORG_ID` environment variable to your organization ID from claude.ai (visible in network requests to `/api/organizations/*/usage`)

## Usage

```bash
# Human-readable format
claude-usage
# Session:  45%  (resets 18:00)
# Week:     29%  (resets 2025-12-27)

# Raw JSON from API
claude-usage --json

# Compact format for statusbars
claude-usage --statusbar
# ████▌░░░░░ 45% 2h 15m|45|██▊░░░░░░░ 29% 4d 5h|29

# Claude Code service status from status.claude.com
claude-usage --status
# operational
```

## i3status integration

`i3/claude-usage.sh` wraps `claude-usage` with caching and outputs i3bar-compatible JSON blocks, including a service status indicator dot.

### Output

Three JSON blocks prepended to your i3status bar:

| Block | Description | Colors |
|-------|-------------|--------|
| `●` | Claude Code service status | green = operational, yellow = degraded, orange = partial outage, red = major outage, blue = maintenance, gray = unknown |
| `████░░ 40% 2h` | Session usage (5-hour window) | green < 70%, yellow >= 70%, red >= 90% |
| `██░░░░ 20% 3d` | Weekly usage (7-day window) | same thresholds |

### Cache

Two independent caches to minimize API calls:

| Cache | TTL | File |
|-------|-----|------|
| Service status | 60s | `/tmp/claude-status-cache` |
| Usage data | 300s | `/tmp/claude-usage-cache` |

Both fall back to stale cached values on fetch failure.

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
