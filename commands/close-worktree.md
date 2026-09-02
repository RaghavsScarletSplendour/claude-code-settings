---
description: Tear down a git worktree safely in any repo — refuse to destroy unmerged work, free its ports, remove the tree, delete the branch, prune. Never rm -rf.
argument-hint: [worktree-name] [--force] [--and-merged-branches]
---

# /close-worktree

Teardown gets hand-dictated every time ("clean up this worktree and brach", "deletr this
worktree") and the debt accumulates — in one repo it had reached **12 live worktrees, 43
local branches, 6 merged-but-undeleted**. This does it correctly, in any repo.

Works standalone: it does **not** assume the worktree was made by `/new-worktree`.

## ⚠️ The two ways this destroys real work — read before running

1. **A worktree's `node_modules` / `.venv` / `vendor` may be symlinks into the main
   checkout's** (a common bootstrap trick, and exactly what this repo's `/new-worktree`
   does). `rm -rf "$WT/frontend/node_modules/"` — with the trailing slash — then deletes
   **main's deps through the link**. **Never `rm -rf` a worktree.** Always
   `git worktree remove`, which removes the link and not its target.
2. **Deleting a worktree with uncommitted or unpushed work is unrecoverable** — there is no
   reflog for a commit that was never made. So this **refuses by default**, and only
   proceeds when the work is provably safe or you pass `--force`.

## Inputs

- `$1` = worktree name or path. If omitted, target the worktree the shell is currently in.
  If that resolves to the **main checkout**, stop, print `git worktree list`, and ask —
  never guess which one to delete, and never delete the main checkout.
- `--force` — proceed despite dirty/unmerged work. State exactly what will be lost first.
- `--and-merged-branches` — also delete local branches already merged into the default
  branch (the "…and any local branches" half of the usual request).

## Steps

1. **Resolve the repo and the target — from the cwd, not a hardcoded path.**
   ```bash
   MAIN=$(git rev-parse --path-format=absolute --git-common-dir); MAIN=$(dirname "$MAIN")
   git -C "$MAIN" worktree list
   ```
   Match `$1` against that list (worktrees may live under `worktrees/`, `.claude/worktrees/`,
   or anywhere). If it matches nothing, show the list and stop.

   **Resolve the default branch, then prove it exists** — `origin/HEAD` goes stale and lies.
   (Verified: `~/.claude` has `origin/HEAD -> origin/master` while its only branch is `main`.
   Trusting it blindly makes every merge check below compare against a branch that isn't
   there, and the gate fails open.)
   ```bash
   pick_default() {
     for c in "$(git -C "$MAIN" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')" main master; do
       [ -n "$c" ] || continue
       if git -C "$MAIN" rev-parse --verify --quiet "refs/heads/$c" >/dev/null; then echo "$c"; return; fi
     done
     return 1
   }
   DEFAULT=$(pick_default) || { echo "❌ can't determine the default branch — pass it explicitly"; exit 1; }
   echo "default branch: $DEFAULT"
   ```
   If no candidate resolves to a real local branch, **stop and ask** — do not fall back to a
   guess, because every safety check in step 2 is measured against `$DEFAULT`.

2. **Safety gate — this is the whole point of the command.** Compute all three, print them,
   and **stop unless all are clean** (or `--force` was given):
   ```bash
   WT=<resolved path>; BR=$(git -C "$WT" rev-parse --abbrev-ref HEAD)
   git -C "$WT" status --porcelain                                  # (a) uncommitted changes?
   git -C "$WT" log --oneline "$DEFAULT".."$BR"                     # (b) commits not on the default branch?
   git -C "$WT" log --oneline @{upstream}..HEAD 2>/dev/null         #     ...and not pushed?
   git -C "$MAIN" branch --merged "$DEFAULT" | grep -qx "  $BR" && echo MERGED || echo NOT-MERGED
   ```
   **The exception that keeps this usable:** a bootstrap commit left by `/new-worktree`
   (subject matching `chore: init worktree …`, which only rewrites a dev port) is **not real
   work**. If that is the *only* unmerged commit, treat the branch as clean and proceed
   without `--force`. It must never reach the default branch anyway.

   If there IS real work, print exactly what would be lost — branch, commit subjects, dirty
   files — and ask. Do not soften this into "looks fine".

   **From here on, `$MAIN`, `$WT`, `$BR`, and `$DEFAULT` mean the concrete values you just
   resolved above — not a shell variable you expect to survive into a new command.** Each
   step below is its own fenced code block, and each one you run is a fresh shell with no
   memory of the last (this environment says so explicitly: "shell state does not persist
   between commands"). If you run steps one block at a time, substitute the literal
   resolved path/branch name into each block yourself before running it. Only leave the
   `$WT`/`$BR`/`$MAIN` references as-is if you're pasting the remaining steps together into
   one Bash call. This matters most for step 4's Docker cleanup below — an empty `$WT` there
   degrades a safe, narrow match into one that matches nearly every container on the
   machine, which is exactly the failure its own guard exists to catch. Treat that guard as
   a backstop, not a substitute for carrying the real value forward.

3. **Free its ports**, if the worktree recorded any (`/new-worktree` writes `.worktree-ports`;
   otherwise skip — don't go hunting for processes to kill):
   ```bash
   [ -f "$WT/.worktree-ports" ] && . "$WT/.worktree-ports"
   for P in "${BACKEND_PORT:-}" "${VITE_PORT:-}"; do
     [ -n "$P" ] && lsof -ti tcp:"$P" | xargs -r kill 2>/dev/null
   done
   ```

4. **Remove the tree — with `git worktree remove`, never `rm -rf`** (see the symlink trap):
   ```bash
   git -C "$MAIN" worktree remove "$WT"      # --force ONLY if step 2 passed or --force was given
   git -C "$MAIN" worktree prune
   ```

   **Also clean up a lingering `/pr-audit` report.** `/pr-audit` writes a report to
   `tasks/audit_<branch>.md`. This file can survive worktree teardown and users otherwise have
   to ask for its removal by hand. Check for it. Delete it
   if present. Require `$MAIN` and `$BR` to be non-empty first — an empty value here just
   makes the check silently useless (never destructive), but check anyway for clarity:
   ```bash
   if [ -n "$MAIN" ] && [ -n "$BR" ]; then
     AUDIT_FILE="$MAIN/tasks/audit_$BR.md"
     [ -f "$AUDIT_FILE" ] && rm "$AUDIT_FILE" && echo "removed $AUDIT_FILE"
   fi
   ```

   **Also stop any Docker containers still bound to this worktree's path** (local Supabase
   dev stacks are the common case — `supabase_db_<project>`, `supabase_studio_<project>`,
   etc.). **Do NOT stop containers by project name or a blanket `docker system prune`** — in
   repos like jdjones-platform, ALL worktrees share ONE local Supabase compose project
   (`jdjones_store_order_automation`), so a same-named container may currently be serving a
   *different, still-open* worktree. The only safe check is the container's actual bind-mount
   source path: since `$WT` no longer exists on disk after step 4's `worktree remove`, any
   container still mounted from inside it is unambiguously orphaned by *this* teardown, and
   nothing else on the machine can be pointing at that exact now-deleted path.
   **This safety argument only holds if `$WT` is actually set.** If you're running each code
   block as a separate command (shell state doesn't persist between them here), re-resolve
   `$WT` at the top of this block rather than assuming it survived from step 2 — an empty
   `$WT` turns the match into "contains `/`", which is every container on the machine. The
   guard below refuses to run rather than risk that:
   ```bash
   if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
     if [ -z "$WT" ]; then
       echo "WT is empty — skipping Docker cleanup rather than risk matching unrelated containers"
     else
       STALE=$(docker ps -a --format '{{.ID}} {{.Names}}' | while read -r id name; do
         docker inspect "$id" --format '{{range .Mounts}}{{.Source}}{{"\n"}}{{end}}' 2>/dev/null \
           | while IFS= read -r src; do
             case "$src" in
               "$WT"|"$WT"/*) echo "$id $name"; break ;;
             esac
           done
       done)
       if [ -n "$STALE" ]; then
         echo "Docker containers still bound to the removed worktree — stopping:"
         echo "$STALE"
         echo "$STALE" | awk '{print $1}' | xargs -r docker rm -f
       fi
     fi
   fi
   ```
   The `case` match (not `grep -F "$WT/"`) catches both "mounted at exactly `$WT`" and
   "mounted at a subpath of `$WT`" — a plain `grep -F "$WT/"` misses the exact-path case,
   which is the common shape for a bare `volumes: - .:/workspace` bind mount.
   Skips silently if Docker isn't installed or isn't running. This only removes stale
   containers left behind by the worktree, not live infra.

5. **Delete the branch.** `-d` refuses to delete unmerged work — that refusal *is* the
   safety, so do not reach for `-D` on your own:
   ```bash
   git -C "$MAIN" branch -d "$BR" || echo "branch '$BR' not merged — kept. Use -D only if you meant to discard it."
   ```

6. **`--and-merged-branches` only** — clear the accumulated merged branches. List them and
   get a yes before deleting:
   ```bash
   git -C "$MAIN" branch --merged "$DEFAULT" | grep -vE "^\*|^\s*$DEFAULT$" | xargs -r -n1 git -C "$MAIN" branch -d
   ```

7. **Report:** worktree removed (path) · branch deleted or kept-and-why · ports freed ·
   worktrees remaining · branches remaining.

## Notes

- If a worktree is already gone from disk but still listed, `git worktree prune` alone fixes it.
- Some repos keep worktrees in more than one directory. Go by `git worktree list`, not by
  guessing a path.
