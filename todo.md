# TODO — from the W30–W31 retro (2026-07-20 → 2026-08-02)

Full evidence and verbatim quotes: `retro/2026-W30-W31-RETRO-REPORT.md`
Status as of 2026-08-03: **nothing below is built.** Review-only pass.

---

## The 7 proposed changes

| # | Change | Kills | Evidence | Where it lands | Effort* |
|---|---|---|---|---|---|
| 1 | ~~**`/ship-pr <n>`** — write-half twin of `/pr-audit` (resolve `.review` `--ours` → squash to trio → apply migration → cherry-pick → `tsc` gate → verify → push → `/close-worktree`)~~ — **DROPPED 2026-08-03.** The trio branch this recipe was built around was promoted to `main` via PR #399 (2026-07-30) and retired repo-wide in 3 follow-up commits (2026-08-02: `#434`, `#436`, `#438`). `docs/SOP_DEV_WORKFLOW.md` now documents a plain feature-branch→PR→main flow with no cherry-pick step, and reserves the merge/prod-migration steps for Raghav, not an autonomous command. The premise is gone. | #6 promotion SOP — **resolved**, same reason | 29 turns / 13 sessions; recipe re-derived **11×** in one session | ~~`jdjones-platform/.claude/commands/`~~ | ~~~1–2h~~ |
| 2 | **Session state file + resume-read hook** — agent writes after every ship, reads on resume | #1 state loss | **14/14** sessions; `/i-have-adhd` 45×, `/compact` 11×, 4 auto-compactions in one session | `~/.claude/` global (spans 4 different projects) | ~2h |
| 3 | **Plain-language as the default** — output-style/config, explicitly **not** a slash command | #4 register | `/eli5` **0** vs `/i-have-adhd` **45** (37 mid-session) | global config / CLAUDE.md | ~30m |
| 4 | **Two `/pr-audit` edits** — add §1 "What this PR actually changes"; fold in browser verification w/ `SKIPPED because X` escape | #5 gaps in the win | 2 sessions burned opening turns; "also do browser tests" re-attached **5×** | edit existing `pr-audit.md` | ~20m |
| 5 | **Railway CLI or MCP access** | #2 transport layer | 65 min lost on demo morning; 438,642-char log paste | your environment (install + auth) — no repo change | ~30m |
| 6 | **Permission allowlist** — read-only Supabase verbs vs prod (`list_migrations`, `SELECT`), `git worktree remove` on a clean tree | #3 classifier | `list_migrations` denied; `SELECT` blocked 2×; `GRANT` blocked *after* `BYPASSRLS` was allowed | `~/.claude/settings.json` | ~20m |
| 7 | **Commit or revert the prod-write-guard softening** | hygiene / safety | dirty since Jul 25, unreviewed | `~/.claude` git | ~5m |

\* Effort is an estimate — **inferred, not measured.**

---

## Checklist

- [x] ~~**1. `/ship-pr <n>`**~~ — DROPPED 2026-08-03, trio retired (see table above)
- [x] **2. Session state file + resume-read hook** — built 2026-08-03, not yet committed
- [ ] **3. Plain-language as the default** (must NOT be a slash command)
- [ ] **4. `/pr-audit`: add "What this PR actually changes" §1**
- [ ] **4b. `/pr-audit`: fold in browser verification** (with explicit skip escape)
- [ ] **5. Railway CLI / MCP access**
- [ ] **6. Permission allowlist for read-only prod verbs + `git worktree remove`**
- [ ] **7. Commit or revert `hooks/supabase-prod-write-guard.sh`**

---

## One row carries risk — weigh, don't just approve

**#6 loosens a security boundary.**
Reads only. Do **not** let it drift into write verbs — that is the exact hole
`supabase-prod-write-guard.sh` exists to close.

---

## Cheapest first move

**#4 — twenty minutes.** Edits an artifact already proven to fire 36 times across 35 sessions.
Zero new surface area, no security implications, no posture change.

---

## Open question carried forward

`permissionDecision:"ask"` — the guard's logic is **verified** (executed against synthetic payloads:
prod write → `ask`, prod read → passes, staging write → passes, wired first on the matcher).
What is **still unverified**: whether this build actually *renders* an approval prompt from `"ask"`
on MCP tools. Testing it means a real prod write, so it was not tested. This is also what would
discriminate the two readings of the Jul 25 softening — post-approval re-litigation (my inference)
vs. the prompt not rendering cleanly and the agent stalling.

## The number to watch next fortnight

**Does `/i-have-adhd` invocation count fall from 45?** It's the purest measure of how often output
was unusable on the first try. If it doesn't move after #3 ships, the problem was never the register
— it was #1, state loss, wearing a costume.
