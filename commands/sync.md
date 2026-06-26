---
description: Safely sync the current git repo with origin — pull then push — handling the recurring no-upstream, divergent-branch, and SSH-timeout snags in one shot.
---

# /sync

Routine git sync (`pull` then `push`) is a zero-decision chore that gets re-typed
constantly and fails in the same fragile ways: a first push silently no-ops on a
branch with no upstream (so "done" gets reported when nothing went up), divergent
branches demand flag retries, and SSH can time out repeatedly. This makes it one
reliable shortcut.

## Steps

1. **Set the safe defaults once** (idempotent — these end the recurring snags
   permanently for this repo):
   ```bash
   git config pull.rebase false
   git config push.autoSetupRemote true
   ```

2. **Show where we stand** before touching anything:
   ```bash
   git status -sb
   git rev-list --left-right --count @{upstream}...HEAD 2>/dev/null || echo "(no upstream yet)"
   ```

3. **Pull** (merge, non-interactive so it can't hang on an editor):
   ```bash
   git pull --no-rebase --no-edit
   ```
   If it reports divergence or conflicts, stop and surface them — do not force
   anything.

4. **Push**, explicitly setting upstream so the no-upstream no-op can't happen:
   ```bash
   git push -u origin HEAD
   ```

5. **SSH-timeout fallback (automatic).** If push/pull fails with an SSH connect
   timeout to `github.com:22`, retry the **same** operation once over HTTPS (443)
   for this command only — don't re-drive "try again" by hand, and don't change the
   saved remote:
   ```bash
   git push -u origin HEAD 2>/tmp/git_err || {
     if grep -qiE "port 22|timed out|connection timed out|could not resolve" /tmp/git_err; then
       echo "SSH timed out — retrying over HTTPS (443) for this push only"
       git -c url."https://github.com/".insteadOf="git@github.com:" push -u origin HEAD
     else cat /tmp/git_err >&2; fi
   }
   ```
   (Same `-c url...insteadOf` wrapper works for `pull`.) Report that you switched
   transport; the override is per-command, so the saved remote is untouched.

6. **Report honestly**: ahead/behind counts after sync, whether the push actually
   moved the remote (compare the printed old..new SHAs — a no-op push prints
   "Everything up-to-date"), and any new/untracked files you did *not* commit.

## Guardrails

- Only commit if the user asked, or if there are staged changes they clearly
  intend to push. `/sync` is about moving existing commits, not authoring them.
- Never `push --force` or `reset --hard` from this command. If history diverged in
  a way a plain merge can't resolve, hand it back to the user.
