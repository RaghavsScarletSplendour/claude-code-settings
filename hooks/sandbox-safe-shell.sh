#!/usr/bin/env bash
# Advisory PreToolUse hook for the Bash tool.
# NEVER blocks (always exit 0). It only surfaces a short note when a command
# matches a known, high-precision shell footgun that has wasted turns before.
# Registered in settings.json under hooks.PreToolUse (matcher "Bash").

input=$(cat)

# Robustly pull the command out of the hook payload; bail quietly if we can't.
cmd=$(printf '%s' "$input" | python3 -c 'import sys,json
try:
    print(json.load(sys.stdin).get("tool_input",{}).get("command",""))
except Exception:
    pass' 2>/dev/null)
[ -z "$cmd" ] && exit 0

warns=()

# 1. Unquoted --include/--exclude glob: an interactive zsh expands or errors on
#    "--include=*.py", so the grep/find silently mis-targets.
if printf '%s' "$cmd" | grep -Eq -- '--(include|exclude)=?\*'; then
  case "$cmd" in
    *"'--include"*|*'"--include'*|*"'--exclude"*|*'"--exclude'*) : ;;  # already quoted
    *) warns+=("Unquoted --include/--exclude glob (e.g. --include=*.py) gets mangled by zsh; wrap the glob in single quotes.") ;;
  esac
fi

# 2. "grep ... || echo ...": grep exits 1 on ZERO matches (not an error), so the
#    fallback fires and misreports a real result as missing.
if printf '%s' "$cmd" | grep -Eq 'grep[^|]*\|\|[[:space:]]*echo'; then
  warns+=("grep exits 1 on zero matches (not an error), so a grep-then-OR-echo fallback misreports. Use a true-fallback, or test the match count explicitly.")
fi

[ ${#warns[@]} -eq 0 ] && exit 0

# Build the JSON in python so newlines/quotes are escaped correctly; never blocks.
printf '%s\n' "${warns[@]}" | python3 -c 'import sys,json
lines=[l for l in sys.stdin.read().splitlines() if l]
ctx="sandbox-safe-shell:\n" + "\n".join("- "+l for l in lines)
print(json.dumps({"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":ctx}}))' 2>/dev/null
exit 0
