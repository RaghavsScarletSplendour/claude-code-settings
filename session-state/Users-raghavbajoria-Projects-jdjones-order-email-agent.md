# Session state — jdjones-order-email-agent

updated: 2026-08-07T16:45:00Z

Local checkout is on `feat/gmail-api-transport` (branched from `origin/main` at
`0374430`, the PR #8 merge). Committed locally, NOT pushed, NO PR yet.

## U-1 SETTLED — VPS facts recorded 2026-08-07 (Raghav ran the commands, outputs pasted, not inferred).

- Both workers write to PROD: shared `/home/raghav/.hermes/.env` has
  `SUPABASE_URL=https://lzyvawfyrisuyikjsgtk.supabase.co`; `systemctl show -p
  EnvironmentFile` is empty for the units (no per-unit env override — workers
  load the shared file via dotenv in code). Outbound's live httpx log lines
  confirm the same host.
- Deployed commit: `0374430` = current `origin/main` (the PR #8 merge). No
  merged-but-not-redeployed gap.
- `gmail-sa.json` present, `-rw------- raghav raghav` (chmod 600, 2393 bytes).
- ⚠️ LIVE SIGNAL: the inbound worker is being IMAP-throttled by Gmail —
  `imaplib.IMAP4.abort: SELECT => [OVERQUOTA] Account exceeded command or
  bandwidth limits` (seen 15:57 UTC); untag detection correctly skipping those
  cycles. IMAP-bandwidth-specific — an argument for cutting over to the Gmail
  API sooner. Likely cause (inferred): full-folder labelled-set re-reads every
  60s.

## Phase 3 — Gmail API transport: BUILT + TESTED locally (4 commits), awaiting push/PR go-ahead.

Plan: `~/.claude/plans/plan-out-phase-3-eventual-quail.md` (approved 2026-08-07;
refines `precious-honking-blossom.md` Phases 3–4). The four commits:
1. `67c935d` feat(transport) — `lib/gmail_client.py` (receive: time-window listing,
   ONE batched `message_id=in.()` dedup via new `sb.seen_message_ids`, raw fetch
   only for survivors so the RFC822 parser + single-part-PDF fix are reused
   verbatim; per-mailbox label-id maps; cached service clients; hourly 7d
   catch-up; `-in:sent` on All Mail), `lib/transport.py` (per-call dispatch on
   EMAIL_TRANSPORT — the worker imports its six mailbox ops from THERE; tests
   monkeypatch those names, don't "simplify" to direct imports),
   `mailbox_creds.current_transport()` + no-secret resolution on gmail_api.
2. `9e4a6c1` feat(send) — gmail branch in `send_threaded`: resumable
   message/rfc822 media, delivered Message-ID read-back (via gmail.modify, NEVER
   gmail.metadata), read-back failure never raises, GMAIL_SEND_DOMAIN gate
   before any Google call. `smtp_client_factory` still forces smtp.
3. `4962c86` fix(outbound) — worker re-checks `can_send` on gmail_api
   (`sb.mailbox_can_send`, tri-state; only explicit false refuses; smtp never
   consults it) + the flip-to-'sent' write now retries 5x (a dropped flip
   re-sent the customer).
4. `65b8f7c` fix(inbound) — attachments accepted by MIME type as well as
   extension (scanned 'scan001' PDFs were dropped); staging failure raises
   AttachmentStagingError and fails the whole message (no more PDF-less rows);
   `size` written per the wire contract. Plus requirements (google libs),
   .env.example/SYSTEM_MAP/README/CLAUDE.md transport docs, SA-key .gitignore
   patterns, and `scripts/verify_gmail_transport.py` (the Phase-4 pre-cutover
   gate: send + read-back + receive with byte-for-byte attachment check +
   label add/read/remove, forcing gmail_api in-process only).

**Verified:** `pytest -q` 124 passed / 0 failed (was 81; +43 new, none of the
existing 81 modified — the five-name interface constraint held). Mock E2E
harness (`tools/mock_e2e_ai_and_manual.py`) green against the refactored
worker. NOT verified: the live Gmail drive — needs the VPS key; that is
exactly `verify_gmail_transport.py` at Phase 4 step 3.

**Paired change committed (not pushed):** `jdjones-architecture` branch
`docs/connected-mailbox-roles` gained `52a9c43` — customer-emails contract now
documents both transports, the worker-side can_send gate (asymmetry closed),
JDJ-261 marked shipped, JDJ-286 folder_cursors marked superseded-by-design,
and the attachment `size` now actually written.

**Next:** on Raghav's go — push + PR this branch; push the architecture
branch/PR #3; then Phase 4 (see the plan): U-1 VPS facts → deploy flag-unset →
`verify_gmail_transport.py` + PO Maker canary → flip → revive platform PR #489.
JDJ-286 (PR #6) and JDJ-246 (PR #4) stay parked — re-check #4 against the new
gmail trash handling before closing.


## ⚠️ This repo runs NO tests in CI. Verified 2026-08-07.

`.github/workflows/` holds exactly four files — `lgtm.yml`, `ok-to-test.yml`,
`require-lgtm.yml`, `strip-approval-labels.yml` — and **none of them invokes
pytest** (counted per file, not inferred from a grep exit code). `ok-to-test.yml`
exists but dispatches nothing that runs a suite. So a green PR here means "a human
typed /lgtm", NOT "the tests passed". Run `python3 -m pytest tests/ -q` locally
before approving anything, and don't read the checkmarks as verification.

## PR #3, #5 — MERGED 2026-08-07.

## PR #5 (`tech2/jdj-261-inbound-recipients`) — MERGED. I pushed a fix commit to it first (`235ed48`).

Not my PR originally; Raghav asked me to audit it and push the fix. It captures
the message's real To/Cc instead of restating the polled mailbox.

**Audited, then fixed three defects in `_addr_list` (one commit, `235ed48`):**

1. **CodeRabbit's finding, and its own example understates it.** The whole header
   was handed to `getaddresses` in ONE call, which returns a single empty pair
   when any element is structurally broken — so every valid recipient beside it
   is lost and the verbatim fallback stores the raw header as one junk blob.
   Measured before the fix:
   `'buyer@koso.co.in, purchase@koso.co.in, Mr. Roy <sroy@jdjones.com>, <<<'`
   → the whole string as ONE "address". Three real recipients gone. Now parsed
   per element (top-level commas only, so a comma inside quotes/angles still
   isn't a separator).
2. **`undisclosed-recipients:;` stored as a recipient** — the standard Bcc-only
   `To:` header, i.e. exactly the case the caller's `or [mailbox_addr]` fallback
   exists for. Non-empty junk meant the fallback never fired. Empty RFC-5322
   groups now yield nothing; a plain unparseable token is still kept verbatim.
3. **NUL bytes reached a Postgres `text[]`** — `_as_text` already strips them on
   the body because a NUL fails the whole insert (costing the entire message).

**Also added the wiring tests the PR lacked** — all 6 original tests called
`_addr_list` directly, so code that parsed correctly but failed to put the values
on the row would have left them green. 62 passed, up from 55. The 5 parser tests
were **verified failing against the pre-fix code**; the 2 wiring tests pass either
way (regression guards, not bug-finders). Mock E2E harness green.

**Blast radius, verified in the platform repo:** inbound `to_addrs`/`cc_addrs`
feed exactly ONE consumer — the "Received by" column in
`frontend/src/apps/so-register/pages/InboxPage.tsx:144`. They do not drive order
creation, sending, classification, threading or dedup, and `from_mailbox` is
shown first and separately. So defects 1–2 were cosmetic; only 3 could lose a PO.

**Next on #5:** CI, then merge. CodeRabbit's comment is unresolved on GitHub — the
fix is pushed but nobody has marked it resolved.

## PR #8 (`fix/multi-mailbox-label-scoping` → `main`) — OPEN, up to date with main, BLOCKED on `/lgtm` only.

**2026-08-07: merged `origin/main` in** (`a85a356`) after #3 and #5 landed.
Deliberately a MERGE, not a rebase — a rebase needs a force-push, which is on the
change-control stop list, and the result is identical.

**Zero conflicts.** `git merge-tree` had predicted one in the `_process` row dict
where #5 and I both add keys; git auto-merged it because the additions sit on
different lines. Verified SEMANTICALLY by reading the merged dict, not by trusting
a clean exit: `to_addrs`/`cc_addrs` (#5) and the `mailbox_id` block (mine) are both
present, nothing duplicated or dropped.

**76 tests pass** on the merged tree. `gh pr checks 8` shows `lgtm-approved: fail
— Comment /lgtm to approve` as the only real blocker; CodeRabbit review in
progress. Nothing there runs a test (see the CI warning above).

https://github.com/JD-Jones-and-Co/jdjones-order-email-agent/pull/8

Part of the SO Register multi-mailbox / Gmail-API work. Paired PRs:
`jdjones-platform#489` (mailbox roles + admin screen) and
`jdjones-architecture#3` (the wire contract).

### Last done (2026-08-07, follow-up round — pushed `f495dc3`)

Two more commits on #8, red-first, plan `~/.claude/plans/tingly-hugging-volcano.md` (approved):

1. `9c50e3f` — **dropped mailbox rows skip label reconciliation like a password
   failure.** `active_mailboxes()` now filters in Python (active, `can_receive`,
   non-blank address) and returns `(kept, dropped)`; `_cycle` skips both label
   passes whenever `unreachable OR dropped` — untick "can receive" on a mailbox
   holding a tagged order and the order now survives (was: dismissed after the
   settle window; test confirmed red first). Also pinned the previously untested
   password-failure guard. Callers updated: worker, mock harness, test helper.
2. `f495dc3` — **spike: no scope recommendation from an empty mailbox.**
   Authenticated-but-nothing-listed now prints "send a message and re-run", exits
   1, no `REQUEST THIS SCOPE SET` (was: exit 0 + recommendation off a bare login).
   Riders: `_probe_modify` removes its throwaway label in a `finally`; `l`→`label`.

81 tests pass locally (was 76; this repo runs no tests in CI — see warning above).

### Earlier commits (original #8 round)

1. `a5dbc83` — **the load-bearing fix.** `_detect_untags` and `_reconcile_labels`
   both compared a mailbox-less view of the world against what Gmail holds, but
   ran INSIDE the per-mailbox loop. At 3 mailboxes (`mailbox_count >
   UNTAG_SETTLE_CYCLES`, default 2) that **dismisses live queued POs out of the
   operator's Inbox and records them `actor='human'`**. At 2 mailboxes the AI
   label lingers forever on dismissed mail. Both now run once per cycle over the
   UNION of every mailbox; an unreadable mailbox skips the pass rather than being
   read as mass untagging. Measured on the real `settle_removals` first: 1 box → 0
   false dismissals, 2 → 0, **3 → 8 over 3 cycles**, 4 → 12.
2. `dc35159` — honours `can_receive` (filtered in **Python**, not PostgREST — the
   column only exists after the platform migration, which is hand-applied, so a
   server-side filter would 400 wherever it hasn't landed and stop polling
   entirely) and writes `customer_emails.mailbox_id` (existed from the start,
   never populated).
3. `4b77b8a` — `tools/gmail_api_spike.py`, Phase 0 of the Gmail API migration.

### Verified

53 passed (was 49). Both regression tests drive the real `_cycle()` so they are
valid against the old code — **confirmed failing before** (the strip test reported
only `box0` was ever searched), passing after. `tools/mock_e2e_ai_and_manual.py`
runs green end to end. No assertion weakened; two call sites updated for the new
signature.

### Spike result (2026-08-07, run by Raghav on the VPS — REAL measurement)

**The delegation grant ALREADY authorizes `gmail.modify` + `gmail.send`** for
the service account impersonating sroy@jdjones.com. Both sets did real reads:
listed=5, raw_bytes=1541908, labels=50, rfc822msgid_hits=1. `gmail.readonly`
is NOT granted (RefreshError) — and not needed. **No Admin-console change is
required; the PO Maker shared-grant risk is moot.** Phases 3–4 (Gmail API
transport in the worker) are fully unblocked. `--probe-modify` also run and PASSED (added=True
removed=True) — label writes proven. Phase 0 is COMPLETE.

### Deployed 2026-08-07: /opt/jdjones/order-email-agent git-ified, hard-reset
to origin/main (post-#8), both workers restarted. Worker verified writing to
PROD (fresh customer_emails rows). `mailbox_id` still NULL on rows captured
around the restart — re-verify with a fresh test email that new-code capture
populates it.

### Next

1. **Check CI on #8** — watch the real gates, not stale `gh pr checks` rows.
2. **Run the scope spike** (Raghav, on the VPS — needs the real key):
   `GMAIL_SA_KEY_PATH=/home/raghav/.hermes/gmail-sa.json python tools/gmail_api_spike.py sroy@jdjones.com`
   Its Google calls are UNVERIFIED; only the guard paths were checked locally.
   Failing before the Admin-console grant change is the expected result.
3. Phases 3–4 of the plan (`~/.claude/plans/precious-honking-blossom.md`): Gmail
   API transport for send + receive. ~2–3 days once unblocked.

### Blockers (all owner-only)

- **CORRECTED 2026-08-07 (live query against lzyvawfyrisuyikjsgtk):** prod DOES
  have `connected_mailboxes` (1 row: so_register, active, non-blank address) and
  `customer_emails` — the platform CLAUDE.md §3 claim that it's missing is STALE.
  Prod does NOT yet have the 20260806120000 roles columns
  (can_receive/can_send/label/updated_at); the worker tolerates that by design,
  but the admin screen's toggles need the migration hand-applied on prod.
- **Which Supabase does the live worker actually write to?** Committed systemd
  units load only the shared `/home/raghav/.hermes/.env` (= prod). Docs say
  staging. Unresolved — `systemctl show -p EnvironmentFile order-email-inbound-worker`
  plus `git -C /opt/jdjones/order-email-agent log --oneline -1` (the deployed
  commit may predate `origin/main`).
- **The delegation grant change is domain-level and shared with PO Maker.** Amend
  additively, then immediately re-run procurement-agent's
  `scripts/verify_gmail_send.py` — a broken `gmail.metadata` scope stops PO Maker
  sending silently for its whole 60s→6h retry ladder.

### Merge order for the five open PRs (file overlap verified by `gh pr view --json files`)

| PR | What | Status |
|---|---|---|
| #3 | factory-notification test | ✅ MERGED 2026-08-07 |
| #5 | real To/Cc recipients | ✅ MERGED 2026-08-07 |
| #8 | mine (multi-mailbox label scoping) | up to date, blocked on `/lgtm` |
| #4 | Gmail delete clears Inbox | **after #8** — same 3 files, also reworks `_detect_untags`, which #8 restructures |
| #6 | JDJ-286 UID cursor | **DECIDE FIRST** — see below |

#4 will need a merge from main after #8 lands; it reworks `_detect_untags`, and
#8 moved that function out of the per-mailbox loop and changed its signature to
take the full mailbox list. Expect a real conflict there, not a mechanical one —
whoever resolves it must preserve #8's cross-mailbox invariant (see CLAUDE.md).

### Open decision

**JDJ-286** (`origin/tech2/jdj-286-inbound-unseen-race`, IMAP UID cursor) —
recommendation: **park it**. The Gmail API fixes the same production bug (mail
opened by a human falls out of `SEARCH UNSEEN` permanently) by a mechanism with no
cursor at all. Building both leaves a permanent dead `folder_cursors` column.
Note the architecture repo previously documented it as shipped and cited a
platform migration that does not exist — corrected in `jdjones-architecture#3`.
Also unmerged and touching the same code: `tech2/jdj-261-inbound-recipients`,
`tech2/jdj-246-gmail-delete-clears-inbox`, `chore/per-worker-env-override`.
