---
name: ci-babysit
description: >
  Own the whole PR-CI loop in one shot instead of making the user poll. Use this whenever the
  user asks to trigger or watch CI on a pull request — "comment /ok-to-test", "ok to test",
  "watch CI", "watch the gates", "check CI status", "check the checks", "tell me when it's
  green", "monitor the pipeline" — or right after you push commits to a branch with an open PR.
  Also use it when the user comes back with "check again": that phrase means the loop was NOT
  babysat and this skill should take over now. One invocation = trigger + background watch +
  a single final report (pass/fail + failing-job diagnosis + migration census). Never make the
  user ask twice.
---

# CI Babysit

## Why this exists

W32 retro finding: the single most repeated interaction of the week (17+ turns across ~15
sessions) was the user hand-driving CI — "comment /ok-to-test" → "watch the ci gates" →
"what's it at now" → "check again" → "all three green?". Each poll costs a round-trip and
attention. The whole loop is mechanical and should cost the user exactly one message.

The second most repeated question, usually asked the moment CI goes green or the PR merges,
was "does this PR have migrations / do I need to apply anything?" — so the final report
answers it unprompted.

## The loop

1. **Identify the PR.** From an explicit number if given, else `gh pr view --json number,url`
   on the current branch. If there's no open PR, say so and stop — don't guess.

2. **Trigger the gate if asked.** If the request includes ok-to-test (or the checks are
   sitting in a "waiting for approval" state), post it:
   ```bash
   gh pr comment <N> --body "/ok-to-test"
   ```
   Post it once. If a fresh `/ok-to-test` already exists on the latest commit, don't re-post.

3. **Watch in the background — never foreground-poll in chat.** Start a background Bash:
   ```bash
   gh pr checks <N> --watch --interval 30
   ```
   Caveat: right after `/ok-to-test`, checks may not be registered yet and `--watch` can exit
   immediately with "no checks". Handle that inside the same background command — retry until
   checks appear (bounded, ~5 min) before starting the watch. Tell the user in one line that
   you're watching and will report when it settles, then keep working or yield the turn.

4. **One final report when it settles.** When the background watch exits:
   - **Green:** say so in one line, then answer the next question before it's asked:
     *"Migrations in this PR: none"* or list each migration file with where it must be
     hand-applied (staging / prod), since in these repos merged ≠ applied.
     To census: `gh pr diff <N> --name-only` filtered for migration paths
     (`migrations/`, `alembic/`, `supabase/migrations/` — whatever the repo uses).
   - **Red:** name the failing check, pull its log tail
     (`gh run view <run-id> --log-failed`), and give a one-paragraph diagnosis: what failed,
     whether it's the PR's fault or a flake, and the concrete next step. If it looks like a
     flake, say so and offer a single retry — don't silently rerun.

5. **Don't stop early.** "Check again" from the user means this skill failed. The background
   watch plus its completion notification is the contract: the user should be able to walk
   away after one message.

## Notes

- Plain language in reports: "the test robot", "green/failed", never raw CI jargon the user
  didn't use first (per global CLAUDE.md).
- This skill watches and reports; it does not merge. Merging stays a human action unless the
  user explicitly says to merge.
- If the user asked to also apply migrations after merge, that is a prod-write path — the
  database-reviewer / prod-write-guard rules apply as usual.
