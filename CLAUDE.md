# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Pure Bash tool that fetches Claude usage quotas from claude.ai and displays them in human-readable or i3status bar format. Also monitors Claude Code service status and benchmark scores from public APIs.

## Architecture

Two-layer design with separation of concerns:

- `claude-usage`: data fetching layer. Reads Firefox cookies for claude.ai API authentication, outputs usage data in multiple formats (`--json`, `--statusbar`, human-readable). The `--status` and `--bench` flags are independent: they query public APIs without authentication and exit early before cookie extraction.
- `i3/claude-usage.sh`: presentation layer for i3bar. Handles caching (three independent caches with different TTLs), color mapping, and outputs ready-to-use i3bar JSON blocks. Falls back to stale cache on fetch failure. Requires `bc` for floating-point comparison in benchmark thresholds.

## Testing

No test framework. Validate changes manually:

```bash
bash -n claude-usage                          # syntax check
bash -n i3/claude-usage.sh                    # syntax check
bash claude-usage --status                    # test status (no auth needed)
bash claude-usage --bench                     # test bench (no auth needed)
CLAUDE_ORG_ID=xxx bash claude-usage           # test usage (needs Firefox session)
bash i3/claude-usage.sh                       # test i3bar JSON output
```

## Key conventions

- `CLAUDE_ORG_ID` env var is required for usage endpoints but not for `--status` or `--bench`.
- `--statusbar` output format is pipe-delimited: `SESSION_TEXT|SESSION_PCT|WEEK_TEXT|WEEK_PCT`. The i3 wrapper parses this, so changes to the format require updating both files.
- Service status values come from the Statuspage API: `operational`, `degraded_performance`, `partial_outage`, `major_outage`, `under_maintenance`.
- Benchmark score is a float (e.g. `92.7`) from `isclaudedumb.today/data/latest.json`, updated daily.
- Cache files live in `/tmp/` (`claude-usage-cache`, `claude-status-cache`, `claude-bench-cache`). Delete them to force a fresh fetch during development.
