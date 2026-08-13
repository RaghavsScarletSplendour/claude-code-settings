# Session state — jdjones-platform

updated: 2026-08-13T06:33:20Z

## SO Register PO-date 422 fix (worktree `so-number-generation-bug-f2986d`) — CODE DONE + VERIFIED, **uncommitted on purpose**

Built the plan `~/.claude/plans/for-da-why-don-t-splendid-barto.md` (D-A date
pickers + D-B useful 422 message). **Nothing committed** — Raghav never said to
commit, and the branch base is contaminated (see below).

**Files:** new `frontend/src/apps/so-register/components/isoDateHelpers.ts` +
`IsoDatePicker.tsx` + `__tests__/isoDateHelpers.test.ts`; edited
`NewOrderPage.tsx` (4 spots), `UploadQuotationModal.tsx` (date branch + payload
guard), `core/api/client.ts` (validation-array branch) + its test.

**One deliberate deviation from the plan, backed by a run:** the plan said no
`dayjs.extend(customParseFormat)` was needed because antd's picker already
extends the singleton. **That is wrong and unsafe** — with the helper imported
in isolation dayjs ignores the format list and falls back to native `Date`:
`12.08.2026` → 2026-**12-08** (December) and `2026-13-45` → 2027-02-14, i.e. a
wrong date that looks right, worse than the 422 being fixed. The helper now
self-extends (idempotent). Red-checked: deleting that one line fails 3 tests.

**Verified live** (local Supabase + backend :8099 + vite :5183, dev-login JWT):
typed `12.08.2026` → saved order T-39 with `po_date = 2026-08-12` (date type,
confirmed by SQL); blank date → F-279 with `po_date IS NULL` (the case that used
to 422); garbage text reverts on blur; a real server 422 through the real client
module now reads `po date: Input should be a valid date or datetime …; market:
Field required` instead of `Request failed with status code 422`.
**Not driven in browser:** the Quotation modal's review phase (needs an AI
extraction round-trip) — covered by its passing unit tests + tsc only.

**A REAL regression was caught here — do not let the "it's just a flaky
timeout" story win again.** `UploadQuotationModal.test.tsx` kept failing one
(different each run) test on a timeout. It looked exactly like the load flake
seen elsewhere. A back-to-back single-file control on a quiet machine proved
otherwise: **baseline 30.1s / 17 pass vs the change 758.9s / 16 pass — ~25x
slower.** Cause: `IsoDatePicker` called `toDayjsOrNull(value)` inline, minting a
new Dayjs identity on every render; in that modal every keystroke in any of the
8 header fields re-renders the grid, so DatePicker redid its work each time.
Fix: `useMemo` on the ISO string → **45.2s / 17 pass**. One line, 17x.
Lesson: a timeout in a file you edited needs a same-machine baseline control
before it can be called environmental.

After the memo, a full-directory control settles it: baseline 647.6s / 1 timeout
vs the change 651.4s / 2 timeouts — same duration, same file, same pattern. So
the *remaining* flakiness of `UploadQuotationModal.test.tsx` under parallel load
is environmental and pre-existing; only the 25x part was mine, and it is gone.

**Gates:** tsc `-b --noEmit --force` clean; so-register + core/api 160 tests
pass; backend `pytest -q` 4418 passed / 0 failed (all 273 errors are integration
= Supabase connectivity, confirmed by an explicit non-integration run). The full
frontend suite shows ~12 failures in administration/marketing/po-maker — those
ARE pre-existing and load-driven (stashed baseline control on the identical
files failed 12 then 10; with the change restored, also 12) and are untouched by
this work.

**BLOCKER before any PR:** this branch's only commit ahead of `origin/main` is
`b838304b "WIP: epitaxy pre-switch from main"` — the contaminated commit
described below (live staging service-role secret in `backend/.env.staging` +
101 unrelated files). Committing and pushing as-is would put that secret in a
PR. Use PR #536's procedure (stash → `reset --hard origin/main` → stash pop)
before committing. Not done unilaterally — it rewrites branch history.

## ⚠️ Local `main` (the main checkout, NOT a worktree) is still contaminated — unrelated to any PR below

`/Users/raghavbajoria/Projects/jdjones-platform` on branch `main` carries a
local-only commit `b838304b "WIP: epitaxy pre-switch from main"` (Aug 11,
1 commit ahead of `origin/main`) that was **never pushed** and is NOT part of
any PR. It was made directly on `main` (against this repo's own rule) and
contains a **live Supabase service-role secret** (`backend/.env.staging`, a
staging key) plus ~356 unrelated files (skills mirrors under `.agents/`/
`.codex/`, a `so_register` reconciliation snapshot meant to stay untracked,
binary xlsx seed files, `node_modules/.vite` cache).

Every NEW worktree branched "from main" since Aug 11 inherits this commit
automatically (confirmed: this affected PR #536's branch below, and
separately the `cartographer-40fc26` worktree referenced in the PR #533
entry). **Check `git log -1 main` in the main checkout before trusting any
future "created from main" branch is clean** — cherry-pick around it (see PR
#536 below for the exact safe procedure: stash, `reset --hard origin/main`,
stash pop) rather than assuming.

Not yet fixed at the source: local `main` itself hasn't been reset, so this
will keep recurring until either (a) Raghav resets local `main` to
`origin/main` (safe — nothing from that commit is pushed, but rotate the
staging service-role key regardless since it sat in local history), or (b)
someone decides to keep/push it deliberately after stripping the secret.
Flagged to Raghav, not yet actioned.

## PR #536 (claude/production-module-exploration-c30729) — OPEN, awaiting Raghav review

**What it is:** Visual-only redesign of the Production module's "New
Production Run" type-picker + Work-Order-lookup screens (previously bare
default-antd Cards, no icons/hierarchy/branding) to reuse the brand design
system already live on the app-launcher home page (`DashboardPage.css`'s
orange/IBM-Plex-Sans/hover-lift-card tokens). Presentational only —
`ProductionForm`/`ProductionHeader` (the big multi-section form after type
pick) untouched.

**Last done (this session):**
1. Started the local stack fresh in this worktree (venv + npm install, local
   Supabase already running shared across worktrees, dev-login JWT mint) to
   see the current UI, since none of it had been visually reviewed before.
2. Ran a Workflow: 3 independent design-direction agents (each read the real
   component files + `DashboardPage.css` directly, no paraphrasing) + 1 judge
   agent that verified antd 6 internals against the installed
   `node_modules/antd/es` source and checked real WCAG contrast math before
   picking/synthesizing a winner — caught two real defects (wrong
   `ant-input-search-button` class name in 2 of 3 proposals; a white-on-orange
   contrast failure) before any code was written.
3. Implemented the judged spec exactly: new
   `frontend/src/apps/production/pages/ProductionEntryPage.css`, className-only
   edits to `ProductionEntryPage.tsx` (Step-0 type grid + header row) and
   `WoLineChecklist.tsx` (WO-lookup's 4 states) — no prop/query/handler changes.
4. **Discovered mid-task:** this branch's tip (`b838304b`) was the contaminated
   commit described above — not this session's work, inherited from local
   `main`. Confirmed via reflog/worktree-list it was never pushed, then
   surgically removed it without touching local `main` or the 2 other
   affected worktrees: `git stash push -u` (redesign files +
   dev-only vite.config.ts port patch) → `git reset --hard origin/main` →
   `git stash pop` → committed only the 3 redesign files, left
   `vite.config.ts` uncommitted/reverted.
5. Re-verified after the rewind (131 commits had landed on `main` underneath):
   `tsc -b --noEmit --force` clean, production vitest scope 36/36 (one
   transient timeout on a concurrent run was confirmed as this machine's
   multi-worktree resource contention, not a regression — reran clean twice
   isolated and in-scope), backend `pytest -q` 4568 passed/0 failed, and a
   full manual re-drive of both redesigned screens in-browser against the
   rebased code (type picker, header chip, WO-lookup idle/empty states,
   manual-entry handoff, non-WO type Stock → form).
6. Pushed (first push, no force needed) and opened
   https://github.com/JD-Jones-and-Co/jdjones-platform/pull/536.
7. CI's auto-monitor flagged 2 failing checks + 1 CodeRabbit comment. Triaged
   both rather than reacting blind:
   - `lgtm-approved`: not a real failure — it's a human-approval gate waiting
     on a `/lgtm` comment. Nothing to fix.
   - `Frontend (typecheck + vitest)`: root-caused as pre-existing and
     unrelated. Confirmed by checking the CI run for the commit that is
     *currently* `origin/main`'s own tip (a docs-only CODEBASE_MAP commit,
     run 31600693128) — same exact failure, same file
     (`src/apps/estimation-dashboard/__tests__/useCrossSection*.test.tsx`,
     debounce-clear assertions like `expected '42' to be ''`), already
     broken on `main` itself, nothing to do with production or this PR's
     diff. Re-confirmed on the 2nd CI run (different subset of the same 3
     tests failed — consistent with CI-load-sensitive timing flake, not a
     new regression). Spawned a separate background task
     (`task_5efed787`) to fix it rather than pulling it into this PR's
     scope.
   - CodeRabbit's one actionable comment (lowercase `Helvetica`→`helvetica`/
     `Arial`→`arial` in `--jp-sans`, a Stylelint `value-keyword-case` nit —
     note: no stylelint config/CI gate actually exists in this repo, this is
     CodeRabbit's own internal linter) — applied as asked despite it making
     this file inconsistent with `DashboardPage.css` (which still has the
     capitalized form, unflagged, since it predates this PR — a real but
     genuinely trivial inconsistency, font-family matching is case-
     insensitive so zero rendering effect). Re-verified in-browser after the
     change: pixel-identical render, as expected. Committed
     (`cf80982b`), pushed, replied on the review thread, resolved it via the
     GraphQL API (CodeRabbit's own bot couldn't resolve it itself due to a
     platform race, but the resolution succeeded and CodeRabbit's follow-up
     comment confirmed the fix independently).
8. Raghav said fix the `Frontend` flake **in this same PR** rather than the
   spawned follow-up. Root-caused precisely: 3 tests (2 in
   `useCrossSection.edge.test.tsx`, 1 in `useCrossSection.test.tsx`) typed a
   value, waited a **hardcoded 600ms**, then asserted the field had settled
   to `''` (rejected by the hook's plausibility check). Under CI's parallel
   load the debounce+correction can take longer than 600ms, so the read
   sometimes lands on the stale intermediate value instead — matches the
   observed failures exactly (e.g. `expected '49.5'/'29.5'/'42' to be ''`,
   never the reverse). Fix: replaced the fixed wait with `waitFor(...,
   {timeout: 3000})`, the same pattern every other assertion in both files
   already uses — same expected final value, just polled instead of read at
   a guessed instant. Did **not** touch the other fixed-600ms-wait tests in
   these files (`keeps a Cross Section...`, `deleting the ID clears
   nothing...`) — those assert the value does NOT change, which a slow
   debounce can't falsely fail, so they weren't part of the flake and were
   left alone (touch the minimum). Verified: edited files pass 22/22 across
   4 separate runs (3 isolated + 1 inside a full-suite run); `tsc -b
   --noEmit` clean. The full local suite itself is currently noisy (17-19
   failed files across unrelated apps, all on this one machine which has 22
   concurrent worktree sessions running) — confirmed those failures share no
   file with this change and don't mention `useCrossSection` at all, so
   the full-suite noise was correctly not treated as a verification signal
   here; real CI is the actual arbiter. Committed (`35bf8976`), pushed.
   Dismissed the earlier-session's spawned follow-up task in spirit (its
   task id was no longer reachable to formally withdraw — ids don't persist
   across app restarts) since the fix is now inline in this PR instead.

**In flight:** nothing running long-term; this worktree's local dev servers
(uvicorn :8199, vite — port reverted to default :5173 in the committed
config, was :5199 locally during verification) are still up in the
background from this session but not load-bearing for anything.

**Next:** Raghav reviews/merges PR #536. CI will re-run on the new push
(`35bf8976`) — expect `Frontend (typecheck + vitest)` to go green now;
`lgtm-approved` still just needs a `/lgtm` comment. Separately: decide what
to do about local `main`'s contamination (see warning above, not part of
this PR). No outstanding follow-up task for the estimation-dashboard tests
— fixed here, nothing left to pick up.

**Blockers:** none for PR #536 itself. The local-`main` cleanup above is
parked pending Raghav's call, not blocking anything.

---

## PR #533 (docs/codebase-map-refresh-20260812) — OPEN, awaiting Raghav review, no CI gates apply (docs-only)

**What it is:** Cartographer regeneration of `docs/CODEBASE_MAP.md`, run from
worktree `cartographer-40fc26` (that worktree's own branch carries an
unrelated local WIP commit and had diverged ~180 files from `origin/main` —
NOT used as the mapping source or the PR source). Mapped from a disposable
detached `origin/main` checkout at `f2f3418d` (131 commits / 563 files since
the last regeneration, `a63910d8`, 2026-08-02).

**Last done (this session):**
1. Fanned out 7 parallel Sonnet `Explore` subagents, each scoped to one
   changed module (`estimation_dashboard`, `po_maker`, `po_so`,
   `so_register`, `marketing`, `core`, `production`+`administration`),
   pre-briefed with the specific commits/migrations/old-map-text to
   verify per module. All 7 read real code and returned dense,
   file-cited reports — saved individually to scratch files before
   synthesis so no report was lost to context pressure.
2. Synthesized all 7 into the map by hand (~942 lines changed) — corrected
   two claims that were flatly wrong (`_RUNTIME_UNGRANTABLE` was documented
   as 5 keys, is actually 6; SO Register's `OrderService.list` bug was
   documented as "confirmed live, not yet fixed," was actually fixed by
   #439), rewrote the Estimation section in full (8→12 products, new
   3-tier RBAC), and added net-new sections for PO Maker's JDJ-293 Feed
   tab and Production's WO-lookup subsystem that the map had never
   documented at all.
3. Verified the result two ways before shipping: (a) spot-checked 8 file
   paths + 2 function names the new content cites directly against
   `origin/main` via `git cat-file`/`git show` — all real; (b) ran
   `check_doc_pointers.py` against a worktree whose files actually match
   `origin/main` (not the stale cartographer worktree) — clean, 0 drift,
   after fixing 2 pointer citations that used a `.../` elision the
   checker couldn't resolve.
4. Created a clean branch (`docs/codebase-map-refresh-20260812`) off
   `origin/main` in a disposable worktree — deliberately not on top of
   the stale cartographer-worktree branch — committed, pushed, opened
   PR #533. Both temp worktrees (the mapping snapshot and the PR branch)
   were removed after use; `git worktree list` confirmed clean.

**In flight:** nothing running.

**Next:** Raghav reviews and merges PR #533 whenever convenient — doc-only
change, no CI gates required per `jdjones-change-control`'s classification
table (`/check-docs` already run and clean, which is the only gate for this
class).

**Blockers:** none. Purely awaiting Raghav's review/merge at his convenience.

---

## PR #485 (feat/estimation-port-from-staging) — MERGED by Raghav. Migrations: 12/12 applied+verified on staging; 10/12 applied+verified on prod, **2 held — avoided a real data-loss risk, need Raghav's answer to finish**. Full report: `tasks/audit_feat-estimation-port-from-staging.md` (worktree `pr-audit-estimation-staging-bfae2a`, not yet copied to the main checkout).

**Migration apply, same session:** Raghav said "apply the migrations,
staging should already be there" — checked live via `list_migrations`
first rather than trusting that: **all 12 were pending on both prod and
staging**, contradicting his expectation (likely conflated with sibling PR
#479's own staging work). Applied all 12 to staging in filename order,
verifying each against its own stated expected outcome — all matched.

Before prod: ran the mandatory `database-reviewer` pass (CLAUDE.md
requires this for any prod write). It flagged that `707`/`712` were seeded
**per-environment, outside any migration** — so prod's actual data was
never guaranteed to match staging's assumed-corrupted starting shape. Ran
its two recommended pre-flight queries on prod directly: **confirmed a real
risk**. Prod's `707` already holds a real, populated 39-band labour-rate
table; `712` uses a live `tableRef: "TABLE_707_LABOUR"` inheritance
mechanism (confirmed against actual current code, not assumed) that
5 products (707/712/703/715/B3_707/B3_707LE) depend on. One migration
(`20260625130000_fix_tables_type_and_alt_graphite.sql`) would have
wholesale-replaced both with a flat-rate placeholder, destroying real
production pricing data for the entire graphite family. A second
(`20260622140000_fix_710v_angular_endcap_offset.sql`) would have
unconditionally overwritten a live value (`endCapOffset`) from prod's
current `50` to `60` — an unexplained third value, not staging's known bug
(2) or fix (60) — a real behavioral change with no way to know if it's
correct without asking.

**Applied the other 10 to prod, holding those 2.** Verified after: RBAC
`estimation:edit` exactly `{admin, estimation_editor, estimator}`; all 4
new products (`701`/`710_RECTANGLE`/`710V_RECTANGLE`/`710_ANGULAR`) present
and active; append-only trigger live; **707's real table and
710V_ANGULAR's `endCapOffset=50` both confirmed untouched** after the
batch.

**In flight:** nothing running.

**Next (Raghav's call, blocking only these 2 migrations):**
1. Is prod's `710V_ANGULAR.metadata.endCapOffset = 50` the deliberately
   correct real-world value, or a bug that also needs fixing to `60` (like
   staging's)? Answer decides whether to apply
   `20260622140000_fix_710v_angular_endcap_offset.sql` to prod as-is.
2. Should prod's real `707`/`712` labour tables actually be replaced with
   the flat-rate placeholder `20260625130000_fix_tables_type_and_alt_
   graphite.sql` writes — or (near-certain answer) does prod need a
   *different*, prod-specific version of that migration that leaves the
   real tables alone and only adds the harmless `710V_ANGULAR` alt-path
   materials? Nothing else in the PR depends on this — safe to leave open.

Everything else about PR #485 is done: merged, CI was fully green before
merge, staging fully migrated, prod has the new products/RBAC/audit-log
table live.

**Blockers:** the 2 held migrations need Raghav's answers above before
prod is fully consistent with staging. Not urgent — nothing else depends
on them.

---

**What it is:** Estimation Dashboard full feature port — calculators for 6
new graphite/PTFE products, a Smart Bulk Estimator (embedded-formula xlsx),
an admin Cost File editor with an append-only edit-audit log, and an
`estimator` → `estimation_viewer`/`estimation_editor` RBAC split (with
`estimator` grandfathered into edit access). 12 migrations, 130 files. Ships
straight to `main` (companion to PR #479, which carries the same content
against `staging`).

**Last done (this session, chronological):**
1. Full read-only `/pr-audit`, verdict GO-WITH-ORDERING — independently
   re-verified migrations (all 12 confirmed pending on both prod/staging via
   `list_migrations`), the RBAC-migration-rename story (queried
   `order_line_items` columns directly on both DBs), RLS/append-only-trigger
   correctness, a twice-found formula-injection fix (re-read the actual
   `_to_number`/`_write_safe_cell` code), backend suite (4801 passed, 0
   failed, on a trial-merged tree), frontend typecheck (genuinely clean).
   One new finding of my own: `AdminPage.tsx` drops `estimator` from the
   Roles-editor dropdown; verified empirically (antd 6.2.0 component probe)
   that this does NOT auto-strip an existing holder's role on save, but has
   zero visual distinction from a valid option — follow-up, not a blocker.
2. GitHub started reporting `CONFLICTING` — PR #511 merged to `main` and
   clobbered the shared `.review/REVIEW.md`. Fixed at Raghav's request:
   merged `main` in, kept `--ours` on the REVIEW.md conflict, verified the
   mechanical merge (tsc clean, #511's own test file 15/15), pushed
   `b7280d6b..6126ff22`. This also closed the "5 behind main" item.
3. Raghav commented `/ok-to-test`. Watched all three dispatched runs (CI,
   Integration, Playwright) to conclusion via `gh run watch`. **Backend
   pytest: pass. Frontend typecheck: pass. Integration: pass. Playwright
   E2E: pass** — this is the exact gate that closed this PR twice before
   over a genuinely red spec in the Square/CS/Thickness area; it is now
   clean for real on GitHub's own runner. **Frontend Vitest: fail** — one
   test, `useCrossSection.squareThickness.repro.test.tsx` › "1b...", 
   `expected '47' to be '20'`. Verified `47 = (100−6)/2`: Cross Section got
   derived from a half-typed ID ("6" of "60") — the same bug *class* the
   whole Playwright/M2 saga was about, on a sibling field, in a unit test
   instead of E2E. Inferred (not proven) mechanism: a 250ms debounce-timer
   race that needs real scheduling jitter to trigger (CI pins Node 22; I
   tested on Node 24). Attempted reproduction: 3 clean local runs unloaded +
   1 more clean run under genuine heavy CPU load (12 `yes` processes,
   confirmed active via `ps aux` during the run) — 0/4 reproductions.
   Checked branch protection directly: only `lgtm-approved` is
   GitHub-*enforced* on `main`; the other 4 gates are required by this
   repo's own CLAUDE.md convention, not mechanically by GitHub. Did **not**
   modify the test or the hook — that call isn't mine to make.
4. Raghav re-ran the failed job himself (`gh run rerun 31494684047
   --failed`). Watched it to conclusion. **Identical failure**: same test,
   same `expected '47' to be '20'` — twice in a row now. This ruled out rare
   jitter (a true fluke wouldn't land on the exact same wrong value twice)
   and upgraded the diagnosis to "reliably fails on GitHub's runner
   specifically" (Node 22, 2-core) — still never reproduced locally (Node
   24) even under heavy load. Could not test Node 22 locally — no
   nvm/volta/fnm/asdf on this machine.
5. Raghav said "fix the CI test." Root-caused to `KEYSTROKE_MS=10` in
   `useCrossSection.squareThickness.repro.test.tsx` giving only 25x margin
   over the hook's 250ms debounce (`SETTLE_MS`) — thin enough that on CI's
   slower/different runner the second keystroke's timer-cancel can land
   late. Fixed **test-only**: `KEYSTROKE_MS` 10→40, and switched test 1b's
   `th` assertion from a bare read to a retrying `waitFor` (matching its
   sibling checks). **Did not touch `useCrossSection.ts`** — no evidence of
   an actual product bug, only a thin test margin. Proved the fix doesn't
   hide a real regression: temporarily disabled the actual guard this test
   exists to catch, confirmed the edited test still fails correctly, then
   restored the hook to a byte-identical diff (verified via `git diff`,
   empty). Ran the edited test 3x clean, full estimation-dashboard suite
   58/58, `tsc` clean. Committed `053eb439`, pushed
   `6126ff22..053eb439`.

6. Raghav said "u commewnt" — read as "you post the /ok-to-test comment
   yourself" (this session's `gh` is authenticated as Raghav's own account,
   confirmed via `gh auth status`; he was directing the action in-session,
   not asking me to bypass anything). Posted it
   (github.com/JD-Jones-and-Co/jdjones-platform/pull/485#issuecomment-5263045767).
   Confirmed the workflow actually dispatched (its trigger condition checks
   the commenter's login, hardcoded to `RaghavsScarletSplendour` specifically
   to block self-approval — this run legitimately matched since the account
   is his). Watched all three to conclusion.

**RESULT: ALL FIVE GATES GREEN, for real, on GitHub's own runner** — Backend
pytest ✓, Frontend typecheck ✓, **Frontend Vitest ✓** (checked the job-level
breakdown specifically, not just the run's overall checkmark — the "Vitest"
step itself passed), Integration Tests ✓, Playwright E2E ✓. The 40ms fix
held on the exact environment that reproduced the failure twice before.
This PR has never been fully green on real CI until `053eb439`.

**In flight:** nothing running.

**Next (Raghav's call):** (1) `/lgtm` → merge — testing is done, nothing
blocking from that side. (2) Migrations: apply all 12 to staging then prod
close to merge time — this PR ships straight to `main` with no staging-only
holding period; this is the one real remaining item. (3) Optional: admin
panel Roles-editor `estimator` visual-distinction follow-up (see step 1
above). (4) Copy `tasks/audit_feat-estimation-port-from-staging.md` out of
the worktree before `/close-worktree pr-audit-estimation-staging-bfae2a`.
(5) Separately, `/close-worktree` on `worktrees/pr-audit-estimation-port-485`
(stale, superseded artifact of an earlier, unrelated audit attempt on this
PR). (6) Branch drifted `BEHIND` main again overnight — not re-checked for
new collisions since; worth a quick look before merge.

**Blockers:** none on testing. Migration apply is Raghav-gated same as
always.

---

## PR #522 (claude/team-app-checklist-alerts-71621c) — JDJ-335 Team Checks app, OPEN, awaiting CI + Raghav review

**What it is:** New `/team-checks` app — per-team adoption checklists; `auto`
items answered by 6 in-code probes over other apps' tables, `manual` items
answered in-app; daily Vercel cron 04:30 UTC sweeps due items and enqueues one
idempotency-keyed digest per run to Raghav via the shared `email_outbox`
(subject `FAIL — ` on critical failures). Plan + G1–G6 decisions + Phase-0
findings: `tasks/jdj335_team_checks_app_plan.md` (in the PR).
Worktree: `.claude/worktrees/team-app-checklist-alerts-71621c`.

**Last done:** Phases 0–4 complete. Migration `20260811090000_team_checks_app.sql`
**applied to STAGING only** (verified 4 tables / 3 perms / 9 role_permissions /
4 triggers); prod is pending, Raghav-only —
`tasks/RAGHAV_team_checks_prod_runbook.md`. Real e2e sweep ran against staging
(Warn/Fail/Pending verdicts value-checked, digest row opened, cron auth
fail-closed confirmed, browser role matrix for 4 personas in the real UI);
all e2e fixtures + temp role grants deleted from staging afterwards.
Full pytest 4373 passed; tsc clean; targeted vitest green (full vitest times
out under machine load — main checkout fails identically; CI arbitrates).

**Next:**
1. Watch PR #522 CI (three gates).
2. After merge: Raghav runs the prod runbook (migration + verify queries +
   first checklists via UI). `CRON_SECRET` already exists in Vercel env;
   `TEAM_CHECKS_DIGEST_TO` optional.
3. Re-POST the feature-map inbox entry — the mini's feature-map server was
   DOWN (port 8787 refused; tailnet HTTPS host serves Mission Control, 404 on
   /api/inbox): `curl -X POST http://raghavs-mac-mini:8787/api/inbox -H
   'Content-Type: application/json' -d '{"title":"Team Checks app (JDJ-335)",
   "text":"New /team-checks app: per-team adoption checklists with auto
   probes + daily digest to Raghav"}'`

**Blockers:** prod DB apply is Raghav-gated (E3, parked in the runbook).

**Gotchas learned:** this worktree had NO frontend node_modules — symlinked
main's. Ports 8000/5173/5273 are held by other projects' stacks; used
8977/5977 with a temp vite config (deleted). `marketing_email_replies` lives
on the PLATFORM DB (prod is the old agents project) and has `approved_at`,
no `updated_at` — MK-01 probe windows on `approved_at`.

## PR #527 (tech2/jdj-338-ampo-kz-india-mislabel-audit) — audit + code review DONE, branch-conflict fixed, awaiting Raghav's `/ok-to-test` + `/lgtm`

**What it is:** New read-only script `backend/scripts/ampo_kz_india_audit.py`
(+ 30 tests) that measures how many Ampo orders already saved as Kazakhstan
were really India (JDJ-338, follow-up to JDJ-334's detector fix). No writes,
no migration, no frontend, no route. Full audit + code review:
`tasks/audit_tech2-jdj-338-ampo-kz-india-mislabel-audit.md` (worktree
`pr-audit-527-c6ce2d`).

**Last done:**
1. Read-only `/pr-audit` pass: code is sound (30/30 new tests pass; full
   backend suite baseline-compared clean on plain `main` — the 274 integration
   errors are pre-existing local-Supabase contention, not this PR).
2. Fixed the merge conflict at Raghav's request: merged `origin/main` into the
   PR branch, resolved the sole conflict (`.review/REVIEW.md`, a shared
   review-packet file that races on every PR) with `--ours`, pushed
   `b2d159ab`. PR is now `MERGEABLE` (was `CONFLICTING`); `lgtm-approved` is
   now properly reported (`failure` / awaiting `/lgtm`, not unreported).
3. Ran a 4-dimension multi-agent code review (correctness, read-only
   safety/injection, test coverage, simplification) with 2-skeptic adversarial
   verification, via Workflow (`wf_3cce1172-bff`). **Did not trust its 19/22
   survival count as-is** — personally re-derived the highest-stakes claims
   against the real code and caught it twice: one "confirmed" finding was
   flatly wrong (claimed JDJ-334's fix isn't in this branch's history —
   `git merge-base --is-ancestor eb386678` proves it is); one finding was
   independently raised twice with CONTRADICTORY verdicts (confirmed once,
   refuted once) because every verifier shared a false premise — "orders are
   never deleted in this codebase." That premise is wrong: `DELETE
   /so-register/orders/{id}` is a real, unguarded, live endpoint
   (`so_register/router.py:533` → `order_service.py:603`). This also corrects
   **my own original audit**, which made the identical wrong assumption when
   calling a CodeRabbit finding "provably unreachable" — corrected in the doc.
   Net: 4 real findings worth a small follow-up commit before Raghav's first
   real prod run (silent-drop-on-delete-race, `CANNOT_VERIFY` render path
   0%-tested, detector-exception path untested, `travelled` can misreport
   "no SO issued" after a PO-replace clears `so_generated_at`), plus a list of
   lower-priority nitpicks. No security issues, no blockers, verdict unchanged.

**Next:** Raghav's own steps (not run by me): `/ok-to-test` on the PR, wait
for CI/Integration/Playwright green, then `/lgtm`, then merge. No DB step —
no migration in this PR. The 4 "worth fixing" findings above are optional
follow-up, not merge blockers.

**Blockers:** none code-side. Merge is Raghav-gated behind the normal
`/ok-to-test` → `/lgtm` sequence (by design — this repo's paid CI gates are
founder-triggered only).
