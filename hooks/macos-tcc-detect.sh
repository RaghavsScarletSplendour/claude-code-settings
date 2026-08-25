#!/usr/bin/env bash
# PostToolUse hook (Bash) — recognize macOS's terminal privacy block (TCC) on the
# first failure instead of letting the agent try 2-3 different approaches
# (ls, cp, osascript/Finder) before figuring out what's actually wrong.
# Retro W30-31 named this fix; it recurred twice more in W35, still unbuilt.
#
# macOS blocks unapproved terminal apps from reading ~/Downloads, ~/Desktop,
# ~/Documents, ~/Pictures unless the terminal has Full Disk Access. The error
# looks like a normal permission/missing-file error, so the model tends to
# retry with a different command instead of recognizing the real cause.
set -uo pipefail
input=$(cat)

cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)
out=$(printf '%s' "$input" | jq -r '(.tool_response.stdout // "") + "\n" + (.tool_response.stderr // "")' 2>/dev/null)
success=$(printf '%s' "$input" | jq -r '.tool_response.success' 2>/dev/null)
combined="$cmd
$out"

# A command that actually succeeded can't be a TCC block, even if its own
# (successful) output happens to contain matching words — e.g. `cat
# ~/Desktop/notes.txt` whose contents mention "permission denied". Only skip
# on a CONFIRMED success; if the field isn't present, fall through to the
# text-pattern checks below rather than going silent.
[ "$success" = "true" ] && exit 0

# Only fire when BOTH a protected-folder path AND a permission-style failure appear.
printf '%s' "$combined" | grep -qiE '(~|\$HOME|/Users/[^/]+)/(Downloads|Desktop|Documents|Pictures)\b' || exit 0
printf '%s' "$out" | grep -qiE 'operation not permitted|not authorized|permission denied|errAEEventNotPermitted|-1743' || exit 0

jq -cn '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:"That failure is very likely macOS blocking terminal access to a protected folder (Downloads/Desktop/Documents/Pictures) — not a missing file or a real permission bug in your command. Do NOT retry with a different tool (osascript, Finder, cp with sudo, etc.) — none of them bypass this from an unapproved terminal app. Instead, ask the user to either (a) copy the specific files you need into a folder you can already reach (e.g. the project directory or /tmp), or (b) grant this terminal app Full Disk Access in System Settings > Privacy & Security, if this comes up often enough to be worth it."}}'
exit 0
