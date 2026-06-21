---
description: Scan ~/.claude for broken plugin entries and other config rot the CLI silently skips, and clean them up with JSON re-validation.
---

# /clean-claude-config

`claude plugin uninstall` silently no-ops when a plugin's entry in
`installed_plugins.json` is empty or malformed (an empty array instead of an
install record), so a "removed" plugin lingers and you fall back to hand-editing
+ re-validating JSON. This command finds and fixes that class of rot directly.

## What to check

1. **Broken plugin entries** in `~/.claude/plugins/installed_plugins.json`:
   - Read the file. For each key under `plugins`, an entry whose value is an empty
     array `[]`, `null`, or otherwise missing an `installPath`/`version` is a
     broken/ghost entry the CLI can't uninstall.
   - List each one and what's wrong, then (with the user's ok) remove those keys.
   - **Cross-check `settings.json` → `enabledPlugins`**: a plugin set to `false`
     there but with no real install record is just dead config — offer to drop it.
     A plugin enabled `true` but absent from `installed_plugins.json` is a dangling
     reference — flag it.

2. **Re-validate after every edit** so you never leave the config unparseable:
   ```bash
   python3 -m json.tool ~/.claude/plugins/installed_plugins.json > /dev/null && echo "installed_plugins.json valid"
   python3 -m json.tool ~/.claude/settings.json > /dev/null && echo "settings.json valid"
   ```

3. **Report** what was removed and what was left, and whether a `/reload-plugins`
   or restart is needed for it to take effect.

## Guardrails

- This repo (`~/.claude`) syncs to GitHub and may be public. **Never** stage or
  commit machine-local / secret-bearing files while cleaning. In particular, leave
  `settings.json`'s session-only fields alone (e.g. an `effortLevel` bumped via
  `/effort` for one session) — do not commit those.
- Only delete entries you've shown the user and they've approved. Don't "tidy"
  beyond broken entries; an unfamiliar-but-valid plugin is not rot.
