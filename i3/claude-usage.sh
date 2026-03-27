#!/bin/bash
# Wrapper for claude-usage with caching
# Outputs i3bar JSON blocks ready to prepend to i3status output

USAGE_CACHE="/tmp/claude-usage-cache"
USAGE_TTL=300  # 5 minutes

STATUS_CACHE="/tmp/claude-status-cache"
STATUS_TTL=60  # 1 minute

get_color() {
    local pct=$1
    if [[ $pct -ge 90 ]]; then
        echo "#FF5555"  # Red
    elif [[ $pct -ge 70 ]]; then
        echo "#FFFF55"  # Yellow
    else
        echo "#55FF55"  # Green
    fi
}

get_status_color() {
    case "$1" in
        operational)          echo "#55FF55" ;;  # Green
        degraded_performance) echo "#FFFF55" ;;  # Yellow
        partial_outage)       echo "#FFAA00" ;;  # Orange
        major_outage)         echo "#FF5555" ;;  # Red
        under_maintenance)    echo "#55AAFF" ;;  # Blue
        *)                    echo "#888888" ;;  # Gray
    esac
}

json_block() {
    local text=$1 color=$2
    printf '{"full_text":"%s","color":"%s"}' "$text" "$color"
}

read_cache() {
    local file=$1 ttl=$2
    if [[ -f "$file" ]]; then
        local age=$(($(date +%s) - $(stat -c %Y "$file")))
        if [[ $age -lt $ttl ]]; then
            cat "$file"
            return 0
        fi
    fi
    return 1
}

# Service status (1-minute cache)
# Cache hit sets $status; cache miss runs the block (same shell, not a subshell)
status=$(read_cache "$STATUS_CACHE" "$STATUS_TTL") || {
    fresh=$(~/.local/bin/claude-usage --status 2>/dev/null)
    if [[ -n "$fresh" && "$fresh" != "unknown" ]]; then
        status="$fresh"
        echo "$status" > "$STATUS_CACHE"
    elif [[ -f "$STATUS_CACHE" ]]; then
        status=$(cat "$STATUS_CACHE")
    else
        status="unknown"
    fi
}
status_color=$(get_status_color "$status")

# Usage data (5-minute cache)
usage_raw=$(read_cache "$USAGE_CACHE" "$USAGE_TTL") || {
    usage_raw=$(~/.local/bin/claude-usage --statusbar 2>/dev/null)
    if [[ -n "$usage_raw" ]]; then
        echo "$usage_raw" > "$USAGE_CACHE"
    fi
}

if [[ -z "$usage_raw" ]]; then
    if [[ -f "$USAGE_CACHE" ]]; then
        usage_raw=$(cat "$USAGE_CACHE")
    fi
fi

# Build i3bar JSON blocks
blocks=$(json_block "●" "$status_color")

if [[ -n "$usage_raw" ]]; then
    IFS='|' read -r session_text session_pct week_text week_pct <<< "$usage_raw"
    session_color=$(get_color "$session_pct")
    week_color=$(get_color "$week_pct")
    blocks="${blocks},$(json_block "${session_text}" "$session_color")"
    blocks="${blocks},$(json_block "$week_text" "$week_color")"
else
    blocks="${blocks},$(json_block "--" "#888888")"
    blocks="${blocks},$(json_block "--" "#888888")"
fi

echo "$blocks"
