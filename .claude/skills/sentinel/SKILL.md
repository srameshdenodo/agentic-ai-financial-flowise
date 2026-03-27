# Skill: Sentinel Context Guardian

An advanced, stateful health monitor that audits "Token Weight," identifies "Ghost Links," and calculates a Repository Health Score.

## Usage

/sentinel [--full]


## Instructions

1. **Execute Engine:** Run `.claude/sentinel/scanner.sh`.
2. **Analyze Output:**
   - **GHOST_CHECK:** Identify any files listed in `CLAUDE.md` that no longer exist (Dead Links).
   - **SIGNAL:DEBT:** Note any files with high "Token Weight" (large files) that are missing from the `## Context Map`.
3. **Calculate Health Score:** - Start at 100.
   - Deduct 10 points for every "Ghost Link."
   - Deduct 5 points for every undocumented file > 1000 tokens.
   - Deduct 15 points if the `## Context Map` header is missing.
4. **Report:** Display the Grade (A-F), the top 3 most "Expensive" undocumented files (by Token Weight), and a list of Dead Links.
5. **Action:** Offer to generate `CLAUDE.md` snippets for the debt found.