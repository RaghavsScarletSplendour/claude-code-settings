#!/usr/bin/env bash
# SessionStart banner — state which worktree/branch this session is actually in.
# W28 retro: 38 "File does not exist. Note: your current working directory is <repo root>"
# errors and a 53-turn session that opened with "are we in th ecorrect worktree".
# With 12 live worktrees, the agent cannot infer this — so tell it up front.
# Never blocks: exit 0 always. Silent outside a git repo.
set -uo pipefail

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

cwd=$(pwd)
top=$(git rev-parse --show-toplevel 2>/dev/null)
common=$(git rev-parse --git-common-dir 2>/dev/null)
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# A linked worktree's .git is a file, and git-common-dir points outside its toplevel.
if [ -f "$top/.git" ]; then kind="LINKED WORKTREE"; else kind="MAIN checkout"; fi

# Main repo path = parent of the common .git dir (works from any linked worktree).
case "$common" in
  /*) mainrepo=$(dirname "$common") ;;
  *)  mainrepo=$(cd "$top" && cd "$(dirname "$common")" && pwd) ;;
esac

others=$(git worktree list 2>/dev/null | wc -l | tr -d ' ')

msg="Worktree context for this session:
  cwd            : $cwd
  git toplevel   : $top   [$kind]
  branch         : $branch
  main repo      : $mainrepo
  live worktrees : $others (see \`git worktree list\`)

If a path you expect is missing, check you are not in the wrong tree — edit paths relative to
the git toplevel above, not the main repo. Do not \`rm -rf\` a worktree: node_modules/.venv are
symlinks into main's. Use /close-worktree to tear one down."

jq -Rsn --arg event SessionStart --arg m "$msg" \
  '{hookSpecificOutput:{hookEventName:$event, additionalContext:$m}}' 2>/dev/null || true
exit 0
