#!/bin/bash
# =============================================================================
# Kimi Session Cleanup Script
# =============================================================================
# 自动清理超过 N 天的旧 session，释放磁盘空间。
# 保留内存摘要（~/.kimi/memories/sessions/）不受影响。
#
# 用法:
#   bash cleanup-sessions.sh [days]
#   days 默认 7，即保留最近 7 天的 session
# =============================================================================

set -euo pipefail

DAYS="${1:-7}"
SESSIONS_DIR="${HOME}/.kimi/sessions"

if [[ ! -d "$SESSIONS_DIR" ]]; then
    echo "Sessions directory not found: $SESSIONS_DIR"
    exit 0
fi

echo "Scanning sessions older than ${DAYS} days in $SESSIONS_DIR ..."

# Find and remove old session directories
DELETED=0
FREED=0

while IFS= read -r dir; do
    if [[ -d "$dir" ]]; then
        size=$(du -sb "$dir" 2>/dev/null | awk '{print $1}')
        rm -rf "$dir"
        DELETED=$((DELETED + 1))
        FREED=$((FREED + size))
        echo "  Removed: $(basename "$dir") ($(numfmt --to=iec-i $size))"
    fi
done < <(find "$SESSIONS_DIR" -maxdepth 1 -mindepth 1 -type d -mtime +"$DAYS" 2>/dev/null)

if [[ $DELETED -eq 0 ]]; then
    echo "No sessions older than ${DAYS} days found."
else
    echo ""
    echo "Done: removed $DELETED session(s), freed $(numfmt --to=iec-i $FREED)."
fi
