---
updated: 2026-09-05T21:10:00Z
project: /Users/raghavbajoria/.claude
---

## Last done
**Prompt-audit code-review follow-up (this session, 2026-09-05, commit 6c7e0e2):**
fixed the last real findings from `/code-review` of the prompt-audit commits —
CLAUDE.md manual paragraph split into short sentences; verify-reminder.sh stale
MANDATORY/W27-W28 comment rewritten and its emitted text split at the semicolon;
weekly-retro heading lost its `(W28)`; the duplicated one-line disclaimer removed
from 33 agent Examples sections. Left on purpose: SubagentStart manual injection
(subagents have no prior context), CLAUDE.md-vs-hook verify wording (rule + its
reminder, not drift), 10-line rate-limiting.md (one-file-per-section consistency).
All 10 review findings are now closed. Earlier in the same thread: PROACTIVELY
restored on 4 agents (55efa8b); PotionLabs autoMode block removed from global
settings.json (ccc001a, user-approved).

**Concurrent session (stale-branch cleanup) — kept verbatim below:**
Stale-branch cleanup across two projects, run from worktree
`claude/stale-branch-cleanup-3c921d`.

**`.claude` (this settings project):** deleted `test/debug-29205` (identical to
main) and its folder at `/private/tmp/jdj-debug-29205`. Nothing else to do here.

**`jdjones-platform`:** classified ~330 saved branches by comparing their code
directly against the live `main` and `staging` branches (not by save history,
which misses squash-merges). Deleted, with user approval at each step:
- 95 branches on this Mac (all confirmed identical to `main` or `staging`,
  zero real work lost).
- 30 branches on the shared GitHub server (all confirmed identical to `main`
  — user ran the delete command themselves after a safety block on this side;
  verified after with a direct GitHub check, not just local cache).

**Deliberately left untouched, still waiting on the user:**
- 9 server branches that shipped to `staging` but not yet `main` (real
  in-progress work): feat/hr-interview-notes-and-tab, feat/hr-resume-swiper,
  feat/hr-sept-four-issues, feat/rfq-body-only-enquiry-lines,
  feat/rfq-conversation-view, feat/rfq-customer-name-aliases,
  feat/rfq-quote-search-queue, fix/hr-drop-department-location-columns,
  preserve/staging-hr-20260825.
- 1 server branch that changed mid-check because another live session was
  actively editing it: tech2/jdj-167-failed-send-visibility. Do not delete
  without rechecking fresh.
- 63 branches on this Mac and 113 on the server that don't match main or
  staging — real content, no open pull request tracking them. Needs a human
  look, not a blanket delete. Full lists were sent to the user as files
  (V3_review_local.txt, V3_review_remote.txt) during this session.
- 19 branches on this Mac that are safe-looking but still open in a folder on
  disk (full path list was produced this session — see FINAL_blocked.txt /
  the "blocked by worktree" list). Close the folder before deleting.

**Important operational finding, worth remembering for next time:** a
background ("run in background, check later") shell command in this harness
can silently never execute at all, while still showing as "running"
indefinitely — confirmed via `advisor`, not guessed. The tell: a `cat`
process appears as a *direct child* of the background wrapper shell itself
(not of git), identical across unrelated script variants, and the target
output file stays at 0 bytes. Foreground commands (including the same exact
git calls, chunked into small batches) work fine and finish in about a
second. Fix: for anything after this, prefer synchronous foreground calls in
small batches over `run_in_background: true` when checking many git
branches — don't re-diagnose this from scratch.

Also: `jdjones-platform` had another live Claude Code session actively
merging PRs and deleting branches throughout this entire session (confirmed
via `gh pr view` and live `ps` process inspection). Re-fetched `origin/main`
and `origin/staging` immediately before every delete step rather than trusting
an earlier snapshot — this caught at least one branch
(tech2/jdj-167-failed-send-visibility) changing state mid-session.

## In flight
Nothing actively running. All background jobs from this session were killed
cleanly; none left orphaned.

## Next
1. If the user wants to keep going on jdjones-platform: decide what to do
   with the 9 staging-only branches, the 1 changed-mid-check branch, and the
   176 "needs a human look" branches (63 local + 113 remote). None of these
   should be blanket-deleted — they need per-branch judgment or an open PR
   check.
2. The 19 worktree-blocked branches can be revisited once those folders are
   closed (via `/close-worktree` or equivalent), if the user wants to clean
   those up too.
3. `.claude` project: nothing queued. Re-run `/claude-api prompt-audit` at the
   next model release.

## Blockers
None outstanding. One classifier block was hit and correctly respected this
session: `git push origin --delete` on the shared server was blocked by the
auto-mode safety classifier even after explicit user approval of the plan —
had the user run it themselves from their own terminal instead of trying to
route around the block.
