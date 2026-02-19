---
name: googly-versions
description: Google-like version history with a Git backend. Use when the user
  says "versions", "version history", "name this version", "rename version", "show versions",
  "go back", "restore", "undo", "make a copy", "autosave on/off", or "turn on/off autosave".
allowed-tools: [Bash, Read]
---

# Versions

Use "version", "name", and "your files" — never Git jargon (commit, SHA, tag, working tree, etc.).
Strip `[auto]` and `[restore]` prefixes when displaying. Never show raw terminal output.

NEVER push, force-push, reset --hard, clean -f. All operations stay local.
Rebase is allowed ONLY for renaming versions (message-only reword).

Before executing any command, run setup silently — do NOT show output to the user:

```bash
${CLAUDE_PLUGIN_ROOT}/bin/setup.sh 2>&1
```

## "show my versions"

Run: `${CLAUDE_PLUGIN_ROOT}/bin/versions-show.sh -n 20`
Show the output directly to the user.

**Pagination:** Show 5 versions per page. Track the current offset internally. Navigation commands:
- `n` / `next` — next 5 versions
- `p` / `prev` — previous 5 versions
- `head` — jump to the newest 5
- `tail` — jump to the oldest 5
- `all` — show all remaining versions from current offset

After the table, show context: "Showing N–M of T — say 'n'/'p'/'all'/'head'/'tail' to navigate." When at the start, omit 'p'/'head'. When at the end, omit 'n'/'tail'.

## "show named versions"

Run: `${CLAUDE_PLUGIN_ROOT}/bin/versions-show.sh --named -n 20`
Show the output directly to the user.

## "name this version X"

If empty, ask: "What would you like to name this version?"

Run: `${CLAUDE_PLUGIN_ROOT}/bin/versions-name.sh "X"`
- On success: show the script's confirmation.
- On failure (exit 1, "Already named"): tell the user the current name and ask if they want to rename it.

## "rename version X to Y"

Run: `${CLAUDE_PLUGIN_ROOT}/bin/versions-rename.sh "X" "Y"`
- On success: show the confirmation.
- On exit 2 (multiple matches from find): show the top matches and ask which one.
- On exit 1 (no match): tell the user no version matched.

## "restore version X" / "go back to X"

1. Find the version:
   Run: `${CLAUDE_PLUGIN_ROOT}/bin/versions-find.sh "X"`
   - Exit 2 (multiple matches): show top matches, ask which one.
   - Exit 1 (no match): tell the user.

2. Show the user what they'd restore to and confirm: "This will replace your files with version 'X'. Your current work will be saved first. Ready?"

3. If confirmed, run: `${CLAUDE_PLUGIN_ROOT}/bin/versions-restore.sh HASH`

4. Show: "Restored to version 'X'. Your previous work was saved — say 'show my versions' to see it."

## "undo"

Resolve HEAD~1 to find the previous version. Show the user what they'd go back to, then follow the restore flow above with that hash.

## "make a copy of version X"

1. Find the version:
   Run: `${CLAUDE_PLUGIN_ROOT}/bin/versions-find.sh "X"`
   Handle multiple/no matches as above.

2. Run: `${CLAUDE_PLUGIN_ROOT}/bin/versions-copy.sh HASH "X"`
   Show: "Created a copy in 'DIR'."

## "autosave off" / "turn off autosave"

Run: `${CLAUDE_PLUGIN_ROOT}/bin/versions-autosave.sh off`
Say: "Auto-save off. Your version history is still here — say 'autosave on' to re-enable."

## "autosave on" / "turn on autosave"

Run: `${CLAUDE_PLUGIN_ROOT}/bin/versions-autosave.sh on`
Say: "Auto-save on."
