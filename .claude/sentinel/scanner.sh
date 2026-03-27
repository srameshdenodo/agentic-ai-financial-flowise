#!/usr/bin/env bash
# Sentinel Engine v1.0 - 2026 Edition
set -euo pipefail

CLAUDE_MD="CLAUDE.md"
CONTEXT_MAP_SECTION=$(awk '/## Context Map/{flag=1;next}/^##/{flag=0}flag' "$CLAUDE_MD" || true)

echo "--- SCAN START ---"

# 1. GHOST BUSTER: Check for dead links in CLAUDE.md
echo "SIGNAL:GHOST_CHECK"
{ grep -oE "(\./|[a-zA-Z0-9._-]+/)[a-zA-Z0-9._/-]+\.(ts|js|json|md|py|sh)" "$CLAUDE_MD" || true; } | sort -u | while read -r line; do
    if [ ! -e "$line" ] && [[ "$line" != *"/"* || -d "${line%/*}" ]]; then
        echo "DEAD_LINK:$line"
    fi
done

# 2. CONTEXT DEBT & TOKEN WEIGHT
# We look for files > 1KB or > 50 lines that aren't in the Map
find . -not -path '*/.*' -not -path './node_modules/*' -type f \( -name "*.ts" -o -name "*.js" -o -name "*.json" -o -name "*.md" \) | while read -r file; do
    
    # Estimate Token Weight (approx 4 chars per token for Sonnet)
    FILE_SIZE=$(stat -c%s "$file")
    TOKEN_EST=$((FILE_SIZE / 4))
    LINE_COUNT=$(wc -l < "$file")
    
    CLEAN_PATH="${file#./}"
    
    # Check if in Context Map
    IN_MAP=0
    if echo "$CONTEXT_MAP_SECTION" | grep -qF "$CLEAN_PATH" || echo "$CONTEXT_MAP_SECTION" | grep -qF "$(basename "$CLEAN_PATH")"; then
        IN_MAP=1
    fi

    # Output signal if it's "Significant" but undocumented
    if [ "$IN_MAP" -eq 0 ] && ([ "$TOKEN_EST" -gt 500 ] || [ "$LINE_COUNT" -gt 150 ]); then
        echo "SIGNAL:DEBT|FILE:$CLEAN_PATH|TOKENS:$TOKEN_EST|LINES:$LINE_COUNT"
    fi
done

echo "--- SCAN COMPLETE ---"