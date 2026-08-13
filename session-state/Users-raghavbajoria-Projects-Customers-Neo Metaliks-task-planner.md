updated: 2026-08-06T09:32:19Z

## IN FLIGHT — PR #13: modal scroll-lock fix, CI green + reviewed, merge BLOCKED by permissions
https://github.com/Potion-Labs-AI/Neo-steel-task-planner/pull/13 — branch
`claude/task-planner-scroll-issue-d3ef6a`, commit `6f28eca`, frontend only (4 files, 57
insertions, 0 deletions). All 3 CI checks **pass** (`frontend`, `privacy-gate`, `image` —
confirmed via `gh pr checks 13 --watch`, `mergeStateStatus` clean). `/code-review`-equivalent
done via the `review` skill against the live PR diff (`gh pr diff 13`): verdict **no blocking
issues**, safe to merge — full review text is in this conversation's transcript, not
duplicated here.

**User said "merge it" (explicit, direct authorization) and `gh pr merge 13 --merge` was**
**still BLOCKED**: "Permission for this action was denied by the Claude Code auto mode
classifier." This is a client-side auto-mode restriction, not a GitHub permissions issue
(the gh call itself never reached GitHub — `mergeable: MERGEABLE` beforehand confirms no
conflict). Did **not** attempt to work around it (no direct API call, no alternate merge
path) per instructions — stopped and surfaced it to the user instead. **PR #13 is still
OPEN, unmerged, as of this timestamp.** Whoever picks this up next: either the user merges
it themselves (`gh pr merge 13 --merge` from their own terminal, or the GitHub UI), or they
grant a Bash permission rule that covers `gh pr merge` before asking Claude to retry.

### What the fix does
`Modal` (`frontend/src/components/ui.tsx`) now locks `document.documentElement`'s
`overflow` for as long as any modal is open, via a reference count
(`lockPopupCount`/`lockBodyScroll`/`unlockBodyScroll`) rather than a plain boolean, driven
from the effect's **cleanup** so it fires on every unmount path — not just Close-button
clicks. That matters because the actual bug was: a modal dismissed by navigating away
(not its own close button) never unlocked scroll, leaving the whole app stuck. Two CSS
riders: `scrollbar-gutter: stable` on `html` (stop the lock from shifting layout when the
scrollbar disappears) and `overscroll-behavior: contain` on `.modal-body` (stop the
modal's own scroll from chaining into the page behind it).

### Regression review done before committing
Read every line of the diff and all 4 call sites of `<Modal>` (`TaskDetailModal`,
`CreateTaskModal`, `AdminPage` ×2). Confirmed via grep: no other code in the frontend
touches `document.documentElement.style.overflow`; the two Radix overlays in the app
(`DueDatePicker`'s `Popover.Root`, `FilterSelect`'s `Select.Root`) don't nest inside
`<Modal>` in a way that conflicts (`Popover.Root` has no `modal` prop set, so it doesn't
engage Radix's own scroll lock at all). `npm run test` (21/21), `typecheck`, `lint` all
clean before this was ever committed.

### Live end-to-end verification (the hook-mandated step — not just the test suite)
`backend/.claude/skills/verify` recipe: disposable Postgres (`verify-neo-pg`), real
Alembic migrations, seeded `md.verify` (managing_director) + `teammate.verify` (cfo),
real backend on :8999, real frontend on :5199 (`PLANNER_API_ORIGIN`). Drove it live in
the Claude Browser pane, logged in as `md.verify`:
- Create-task modal: open → `overflow: hidden` confirmed via computed style; opening the
  nested Radix due-date popover inside it does **not** disturb the lock; submit → modal
  closes → `overflow` restored to `""`.
- Task-detail modal: open → locked. Then a **genuine client-side route change** (browser
  **back** navigation, confirmed via `location.pathname` changing with no hard reload) while
  the modal was still open, without ever pressing its close button — this is the actual bug
  scenario. `overflow` correctly restored and dialog count went to 0.
- Admin flow: submitting "Add user" closes that modal and opens "Temporary password" in the
  **same batched state update** (the specific case the reference-count exists for, vs. a
  plain boolean). Confirmed via computed style that `overflow` stayed `"hidden"`
  continuously through the swap, then restored on explicit close.
- One false alarm during this: `overflow` briefly read back as `""` mid-form-fill — turned
  out to be my own misclick landing on the modal backdrop (a stale coordinate reused after
  the nested date-picker popover had already auto-closed), not a product bug. Reproduced
  the correct sequence afterward to confirm.
- Playwright e2e (`test:e2e`) was read but **not executed** this session (needs its own
  backend/db harness) — its two new assertions duplicate what was already confirmed live
  above, so this is a low-risk gap, not an open question.
- Verification env torn down cleanly: uvicorn + vite killed, `docker rm -f verify-neo-pg`,
  `git status` was clean before committing.

### Not done
- `/code-review` was **not** run on this PR (user-triggered only per this repo's
  convention) — flag before merge, same as PR #11's open item below.
- `privacy-gate` CI check had not finished as of PR creation — re-check before merging.

## Next
1. **PR #13 is fully ready (CI green, reviewed, no blocking issues) but merging it needs a
   human** — see Blockers. Once merged (`--merge`, not squash, matching this repo's
   convention), confirm live via production `/health` (commit field), then tear down this
   worktree (`task-planner-scroll-issue-d3ef6a`) with `/close-worktree` — never `rm -rf`.
2. Separately, PR #11 (`claude/cafo-task-tagging-test-51472f`, tests-only) is still open
   from an earlier session — confirm its CI, run `/code-review`, merge, then close that
   worktree too. Not touched this session.

## Blockers
- **PR #13 merge is blocked by the Claude Code auto-mode permission classifier**, even with
  explicit user authorization ("merge it") already given in chat. `gh pr merge 13 --merge`
  was denied client-side before it reached GitHub. Needs either the user to merge it
  directly, or a Bash permission rule added for `gh pr merge` before Claude retries.

## DONE — PR #12: replies feature flag fix, merged, deployed, worktree closed
https://github.com/Potion-Labs-AI/Neo-steel-task-planner/pull/12 — was branch
`claude/neo-metaliks-task-planner-qa-47d0c0`, commit `e226942`, **one-line config change,
zero code touched** (`config/neo.yaml` line 52: `replies: false` → `replies: true`).

Full thread, all in one session: QA pass across the app as 3 roles → found `features.replies`
was dead config (Reply button fully worked despite the flag) → user said "keep it on" → flipped
the flag → PR #12 opened → waited for CI via background `gh pr checks --watch` rather than
merging on pending checks → all 3 checks passed → merged with `gh pr merge 12 --merge` (merge
commit `b7375a88792f7fa926090e3da5fb486fca708734`, matching this repo's non-squash convention) →
confirmed live via production `/health` (`commit` field matched exactly) → worktree torn down
with `/close-worktree`.

**Worktree teardown notes for next time:** the skill's `git branch --merged` check assumed a
two-space branch-list prefix; a branch checked out in a worktree lists with a `+` prefix instead,
so the exact-match grep silently said NOT-MERGED on real merged work. Caught it because the
`$DEFAULT..$BR` commit-diff check (which doesn't depend on listing prefix) came back empty,
which contradicted "not merged" — investigate contradictions between two checks measuring the
same fact rather than trusting the more fragile one. Resolved by fetching `origin/main` (local
`main` was 2 commits stale — the PR was merged on GitHub, not locally), fast-forwarding local
`main`, then re-verifying with `git merge-base --is-ancestor <branch> main` (prefix-independent)
→ confirmed MERGED. All 3 QA-session worktree branches now closed; repo back to just `main` +
the still-open PR #11 branch + one older `task-planner-scroll-issue` branch (that branch is now
PR #13, above).

### What the session covered
User asked to run the whole app and log in as different roles per
`docs/neo-planner-team-quick-guide.md`. Did this for real: disposable Postgres+RLS container,
real Alembic migrations, seeded 4 users (`priya.md`=MD, `arjun.cfo`/`neha.cfo`/`rahul.new`=CFO),
real backend (port 9011) + real frontend (port 5183, `PLANNER_API_ORIGIN` env var — this repo's
own mechanism for running a second instance alongside another project's dev server already on
5173), drove it all in the Claude Browser pane as three different logged-in people. Every
documented feature confirmed working: sign-in incl. first-time password change, board lanes,
task creation (both MD and CFO — capability grant confirmed), untagged vs. `@mention`-sealed
updates (sealing verified against a second CFO on the same task who wasn't tagged), any-assignee
complete, creator-only cancel/reopen with the note prompt appearing only at cancel time, History,
Activity (correctly omits sealed content), Messages (chat visible only to members; "tag a task"
correctly offers only tasks every chat member can see — verified both the positive case and the
negative "no shared tasks to tag" case), and the core privacy rule itself — logged in as the MD
and confirmed she sees **nothing** about a task she's not on, no special-role override.

### The bug found and the fix
`features.replies: false` in `config/neo.yaml` was dead config — grepped and read both frontend
(`UpdateThread.tsx`) and backend (`routers/tasks.py`, `services.py`, `definition.py`): the Reply
button is fully wired end-to-end (threaded replies, audience inheritance, visibility checks) and
**nothing anywhere checks the flag**. Confirmed via a background Explore agent, not just a hunch.
User's call: "keep it on" — i.e. the flag should say `true` since that's what's actually running,
rather than gating the working feature off. Fixed by flipping the config value, not by adding a
new gate (feature already works correctly; the config was the lie).

Also confirmed as a **non-issue**: admin (`manage_users`) and import (`task:import`) routes are
gated server-side (`backend/app/routers/admin.py:35-41`, `imports.py:259,351`), not just hidden
nav — a CFO hitting `/api/admin/*` directly still gets a real 403.

### Not done
- Test harness (disposable Postgres container `verify-neo-pg-qa47d0c0`, uvicorn, vite) was torn
  down cleanly at session end — nothing left running, `git status` was clean before this commit.
- (PR opened, merged, deployed, and worktree closed later in this same session — see the DONE
  section above this one.)

## IN FLIGHT — PR #11: tests for a CFO sealing an update to the MD (unchanged from last session)
https://github.com/Potion-Labs-AI/Neo-steel-task-planner/pull/11 — branch
`claude/cafo-task-tagging-test-51472f`, commit `4df46c5`, **tests only, 262 insertions, zero
product-code change**. Still **OPEN**, not merged (confirmed via `gh pr view 11` this session —
`mergedAt: null`). CI status not re-checked this session; last known state was pending with an
expectation of **79 passed**. Not touched this session either.

### The question that PR answers, and the verdict
"An MD creates a task; a CFO on it tags the MD in the status update bar — do the other people on
the task stay blind?" **Yes.** Verified at the app tier and in Postgres with RLS forced.
Nothing to do with CFO task-creation; gated by `require_participant` only, no capability check.
The MD sees the sealed update anyway because she's the **creator** (creators see all sealed
updates on their own task) — not a bug, disclosed verbatim in the composer.

### Not done on PR #11
- `/code-review` was NOT run (user-triggered only). Flagged as a note in the PR body. Run before
  merge.

## DONE earlier — assignee-change 500 fixed, live in production
Commit `46e0525` ("Fix assignee-change 500 under notification RLS") is on `origin/main` and
running in production (`/health` reports it). App code only, no migration. Verified in a browser
against real Postgres+RLS, with the instrument check passing: the pre-fix `services.py` really did
return **500** `UniqueViolation: uq_notification_episode` in that harness, and the restored file
returned **200** on the same database and task.

Reviewed inline after the push (same `/code-review` limitation). No blocking defects. Three
non-blocking notes that are still open:
1. a **re-added assignee gets no fresh "assigned" alert** — the stale row wins the conflict, so the
   fix trades a crash for a silently missing notification;
2. `on_conflict_do_nothing()` is **untargeted** — any unique constraint added to `notifications`
   later would silently drop rows instead of erroring;
3. **nothing in the frontend calls `/api/notifications`** (grepped), so `ensure_overdue_notifications`
   is unreachable in the product.

Also still deferred: no `IntegrityError` → HTTP mapping (bare 500 body), the error box renders far
from the control that failed, and the wider "app reads through the privacy filter but writes past
it" class has no structural guard — only `notify_assignees` / `notify_mentions` /
`ensure_overdue_notifications` were routed through `_insert_notification_if_absent`.

## DONE earlier — CFO task creation (shipped 2026-08-04, closed out at `fc38d49`)
Production-verified as both roles; test task cancelled; that worktree torn down. Two facts that
stay useful:
- **Merged ≠ deployed here.** No deploy workflow in `.github/workflows/` (CI only pushes an image
  on `v*` tags); Railway deploys from its own GitHub integration. `GET /health` returns the running
  commit — that field is the only honest deploy check.
- **"Get a TSK-#### number back" is not observable in the product** — `TaskOut` exposes no
  task-number field and the UI never renders one. Don't go hunting for it.

## Reusable gotchas
- **`backend/.claude/skills/verify`** is the right instrument for anything touching RLS/policy —
  and, as of this session, also the fastest path to a real backend for **frontend** runtime
  verification (log in as a seeded user, drive the UI for real) when the change under review has
  no RLS angle at all. Its step-4 note "cfo (no capabilities)" is **stale** — `config/neo.yaml` now
  grants cfo `task:create`.
- **The unscoped `verify` skill has `disable-model-invocation` set** — cannot be called via the
  Skill tool directly even when CLAUDE.md marks it mandatory. Fall back to the `run` skill, which
  will surface any project-specific `.claude/skills/*/SKILL.md` (this repo's lives under
  `backend/.claude/skills/verify/`, not the repo root — the upward-search one-liner in the `run`
  skill only checks the current dir and its parents, so it won't find a skill that lives in a
  *subdirectory* like `backend/`; check there by hand if the upward search comes up empty).
- **Browser-pane `preview_start` port mismatch**: passing bare `npm run dev` via `.claude/launch.json`
  let Vite's own auto-increment (port already busy → tries 5174, 5175, â€¦) race the preview tool's
  own `autoPort` port assignment — they picked *different* ports and `navigate` to the tool-reported
  port failed. Fix: read the actual bound port from `preview_logs`, then `navigate` straight to
  `http://localhost:<that port>` instead of trusting the tool's reported port when autoPort fired.
  Simpler alternative used later the same session: skip `preview_start` entirely, launch the vite/
  uvicorn processes yourself in the background with an explicit `--port`/`--strictPort`, and just
  `navigate` straight to that known port.
- **`computer` click coordinates are screenshot-pixel space, and the screenshot tool returns images
  smaller than the real viewport** (800×450 image for a 1280×720 viewport this session). Eyeballing
  a coordinate off a mentally-zoomed-in reading of the image is a reliable way to click the wrong
  thing. Prefer `read_page` → click by `ref` over any hand-picked coordinate; re-run `read_page`
  after anything that changes the DOM (modal open/close, popover open/close) before clicking again
  — a `ref` (or a coordinate) captured before the change can silently resolve to the wrong element
  or an already-closed overlay's backdrop.
- **A modal's full-screen backdrop (`position: fixed; inset: 0; z-index: 100`) blocks real mouse
  clicks on everything behind it, including sidebar nav links** — so "user clicks a sidebar link
  while a modal is open" is not actually reachable by mouse in this app. The equivalent real
  scenario is a **client-side route change that isn't a click on the covered page** — browser
  back/forward, or a programmatic redirect — which bypasses backdrop hit-testing entirely because
  it's not pointer-driven. Test that instead when a unit test's "simulates navigating away" framing
  doesn't survive contact with the real backdrop.
- **`mcp__Claude_Browser__navigate` to a full URL does a hard page load**, not client-side routing —
  proved by `document.documentElement.style.overflow` trivially reading `""` afterward regardless of
  whether the app's own cleanup logic is correct, because the whole document reloaded. Use
  `navigate({url: "back"})` (or `"forward"`) to exercise a *real* client-side/SPA transition when
  the thing under test is unmount/cleanup behavior, not page-load behavior.
- **Worktrees may have no `.venv` or `node_modules`.** Use the main checkout's Python interpreter
  directly: `/Users/raghavbajoria/Projects/Customers/Neo Metaliks/task-planner/backend/.venv/bin/python`.
  For frontend, symlink `frontend/node_modules` to the main checkout's — no `.venv`-style symlink
  is pre-created for it the way the reminder banner implies.
- **Running two Neo Planner instances (or alongside another project's dev server) on one
  machine**: frontend defaults to port 5173 via `vite.config.ts`, which reads `PLANNER_API_ORIGIN`
  (defaults `http://127.0.0.1:8000`) to proxy `/api` and `/health` — pass a free port to `vite
  --port` and set `PLANNER_API_ORIGIN` to point at wherever uvicorn is actually running. Don't
  assume 5173/8000 are free in a multi-project session.
- **CI splits the databases**: app suite on `neo_planner_test` as **superuser** (RLS bypassed
  there — app-tier tests do NOT prove RLS), RLS tests on `neo_planner_rls` as `planner_runtime`.
  Migrate **both**. Counts: 68 app + 11 RLS = 79.
- **RLS tests need `TEST_POSTGRES_ADMIN_URL` / `TEST_POSTGRES_RUNTIME_URL` by those exact names.**
  With any other names every test in that file silently **skips** and pytest exits 0.
  **Check the count, not the exit code.**
- **Postgres container auth trap**: the image's `pg_hba.conf` has `host all all 127.0.0.1/32 trust`,
  so `docker exec psql` accepts **any** password — an in-container login check is a **broken
  instrument**. Only host-side connections do real SCRAM; verify the runtime role from the host.
- One unexplained SCRAM failure for `planner_runtime` (worked, then didn't, then worked after
  re-issuing `ALTER ROLE ... WITH PASSWORD`). Never root-caused. If it recurs, re-set the password
  rather than re-architecting the harness.
- **Search assertions need an instrument check.** A first draft searched "dispatch", which matched
  the task **title** an excluded assignee can legitimately see — the test failed for the wrong
  reason. Use a nonsense token unique to the sealed body, and assert a title search *does* hit
  first, so an empty result cannot pass vacuously.
- **Browser-pane gotchas**: `computer scroll` times out with "Browser pane is currently hidden" —
  use `computer{action:"scroll_to", ref}` from a fresh `read_page`. Modals animate; screenshot,
  `scroll_to`, screenshot again before clicking. Element refs re-number after every save. Clicking
  by raw screenshot coordinate can miss mid-animation or after a scroll-position change even when
  the coordinate looked right in the prior screenshot — prefer clicking by `ref` from a fresh
  `read_page` over coordinates whenever the DOM might have shifted (modal open/close, calendar
  popover open/close, sign-out transition).
- **Wheel-scroll simulation is unavailable in this Browser pane** — verify scroll-chaining /
  scroll-lock bugs via computed styles (`getComputedStyle`, `element.style.overflow`) and real
  interactive flows (clicks, route changes), not simulated `wheel`/`PageDown` events.
- **Reading `features.*` flags in `config/neo.yaml` is not proof they're enforced.** `ai` and
  `view_all_tasks` are checked (`backend/app/definition.py:68,70`); `replies`, `projects`,
  `erp_integration`, `analytics_ui` were not (as of the PR #12 session, `replies` is now
  intentionally `true` to match reality — the others are unverified, don't assume they're either
  honored or dead without checking).

Rule: if the user's first message is state-seeking ("what's next", "where are we",
"status", or no message at all) — your first line must be this file's Next value,
verbatim, unless the STALE FLAG above says otherwise. If the user opens with an
unrelated task, follow the task instead; don't force this in.
