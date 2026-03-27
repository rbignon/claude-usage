# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Pure Bash tool that fetches Claude usage quotas from claude.ai and displays them in human-readable or i3status bar format. Also monitors Claude Code service status from the public status page.

## Architecture

Two-layer design with separation of concerns:

- `claude-usage`: data fetching layer. Reads Firefox cookies for claude.ai API authentication, outputs usage data in multiple formats (`--json`, `--statusbar`, human-readable). The `--status` flag is independent: it queries the public `status.claude.com/api/v2/summary.json` endpoint without authentication and exits early before cookie extraction.
- `i3/claude-usage.sh`: presentation layer for i3bar. Handles caching (two independent caches with different TTLs), color mapping, and outputs ready-to-use i3bar JSON blocks. Falls back to stale cache on fetch failure.

## Testing

No test framework. Validate changes manually:

```bash
bash -n claude-usage                          # syntax check
bash -n i3/claude-usage.sh                    # syntax check
bash claude-usage --status                    # test status (no auth needed)
CLAUDE_ORG_ID=xxx bash claude-usage           # test usage (needs Firefox session)
bash i3/claude-usage.sh                       # test i3bar JSON output
```

## Key conventions

- `CLAUDE_ORG_ID` env var is required for usage endpoints but not for `--status`.
- `--statusbar` output format is pipe-delimited: `SESSION_TEXT|SESSION_PCT|WEEK_TEXT|WEEK_PCT`. The i3 wrapper parses this, so changes to the format require updating both files.
- Service status values come from the Statuspage API: `operational`, `degraded_performance`, `partial_outage`, `major_outage`, `under_maintenance`.
- Cache files live in `/tmp/` (`claude-usage-cache`, `claude-status-cache`). Delete them to force a fresh fetch during development.
