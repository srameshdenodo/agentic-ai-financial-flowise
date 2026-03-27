# Skill: Context Audit

Finds the top 5 largest files in the repo and flags any that lack a corresponding entry in `CLAUDE.md` as **Context Debt**.

## Usage

```
/audit
```

## Instructions

Run the following shell script, then interpret and report the results.

```bash
#!/usr/bin/env bash
set -euo pipefail

CLAUDE_MD="CLAUDE.md"
TOP_N=5

# Find top N largest files, excluding .git and node_modules
TOP_FILES=$(find . \
  -not -path './.git/*' \
  -not -path './node_modules/*' \
  -not -path './.claude/*' \
  -type f \
  -printf '%s\t%p\n' 2>/dev/null \
  | sort -rn \
  | head -n "$TOP_N" \
  | awk '{print $2}')

if [ ! -f "$CLAUDE_MD" ]; then
  echo "ERROR: $CLAUDE_MD not found."
  exit 1
fi

echo "=== Context Audit: Top $TOP_N Largest Files ==="
echo ""

DEBT_COUNT=0

while IFS= read -r file; do
  # Strip leading ./
  clean="${file#./}"
  # Check if the file (or its basename) is mentioned in CLAUDE.md
  if grep -qF "$clean" "$CLAUDE_MD" || grep -qF "$(basename "$clean")" "$CLAUDE_MD"; then
    echo "  OK            $clean"
  else
    echo "  CONTEXT DEBT  $clean"
    DEBT_COUNT=$((DEBT_COUNT + 1))
  fi
done <<< "$TOP_FILES"

echo ""
if [ "$DEBT_COUNT" -eq 0 ]; then
  echo "No context debt found."
else
  echo "$DEBT_COUNT file(s) flagged as Context Debt — consider documenting them in CLAUDE.md."
fi
```

After running the script, summarize:
- Which files are **OK** (mentioned in `CLAUDE.md`)
- Which files are **Context Debt** (not mentioned)
- Suggest brief CLAUDE.md entries for any flagged files based on their names/extensions
