#!/bin/bash
# =============================================================================
# Kimi Memory Sessions Cleanup Script
# =============================================================================
# 自动清理超过 N 天的旧 session 摘要，避免 memories/sessions/ 无限膨胀。
#
# 用法:
#   bash cleanup-memories.sh [days]
#   days 默认 30，即保留最近 30 天的 session 摘要
# =============================================================================

set -euo pipefail

DAYS="${1:-30}"
MEM_DIR="${HOME}/.kimi/memories/sessions"

if [[ ! -d "$MEM_DIR" ]]; then
    echo "Memory sessions directory not found: $MEM_DIR"
    exit 0
fi

echo "Scanning memory summaries older than ${DAYS} days in $MEM_DIR ..."

DELETED=0
FREED=0

while IFS= read -r file; do
    if [[ -f "$file" ]]; then
        size=$(stat -c%s "$file" 2>/dev/null || echo 0)
        rm -f "$file"
        DELETED=$((DELETED + 1))
        FREED=$((FREED + size))
        echo "  Removed: $(basename "$file")"
    fi
done < <(find "$MEM_DIR" -maxdepth 1 -type f -mtime +"$DAYS" 2>/dev/null)

if [[ $DELETED -eq 0 ]]; then
    echo "No memory summaries older than ${DAYS} days found."
else
    echo ""
    echo "Done: removed $DELETED summary file(s), freed $(numfmt --to=iec-i $FREED)."
fi
