# Skill: Sentinel Watcher

Monitors logs in real-time. When an error occurs, it cross-references the failing file with the Sentinel Engine to ensure documentation is up-to-date before suggesting a fix.

## Usage

/watch [logfile]


## Instructions

1. **Tail Log:** Default to `combined.log`. Read the last 50 lines.
2. **Error Detection:** Look for `ERROR`, `CRITICAL`, or `500` status codes.
3. **Sentinel Integration:** - Extract the filename from the error.
   - Run `grep "FILE:[extracted_name]" <(.claude/sentinel/scanner.sh)` to check its debt status.
4. **Context-Aware Alert:**
   - If the file has **Debt**, start with: "⚠️ Error in undocumented file [name]. Context may be stale."
   - If the file is **Clean**, start with: "✅ Error in [name]. Documentation is healthy."
5. **Resolution:** Propose a fix and, if the file was undocumented, propose a `CLAUDE.md` entry simultaneously.