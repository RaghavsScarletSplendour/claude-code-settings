# Session state — jdjones-marketing-agent

updated: 2026-08-11T04:05:00Z

## PR #20 (fix/followup-email-issues) — OPEN, waiting on fresh CI + Raghav's /lgtm

**What it is:** the six follow-up-email fixes (escalations deleted,
first-name greetings, no day counter, empty CC default, correct footer
phone/email) + a Raghav-run SQL data fix
(`migrations/fix_followup_templates.sql`). Audit verdict GO:
`tasks/audit_fix-followup-email-issues.md`.

**Last done:** Verified all 8 CodeRabbit inline comments against code and
fixed the valid ones in commit `b5cc3f2` (pushed):
- `_greeting_name` in all 3 engines: initials-only pair ("A","B") now
  returns 'there', never "A B" (fail-before proven: old code returned 'A B').
- SQL F2 phone replace loosened to bare '2282 6800' (audit/update/verify
  now same granularity).
- reply_drafter passes exact `Dear <greeting_name>,` into the prompt.
- systemd/README: `disable --now` before `rm` + verify step.
- CLAUDE.md fallback-ladder wording; docs sample Ashok→Suresh.
- Tests extended; 197 passed locally.
**Skipped deliberately:** CodeRabbit's "drop the 1-2 char length check"
(Rajat's initials guard, kept).

**In flight:** CI re-running on `b5cc3f2` (pytest ×2, reset-lgtm, strip,
CodeRabbit) — was all pending at last check.

**Next:**
1. Confirm CI green on b5cc3f2.
2. Raghav comments `/lgtm` ON PR #20 (his earlier attempt landed in the
   platform repo, not here — verified no /lgtm comment on #20).
3. Merge (`gh pr merge 20 --squash`, no --admin).
4. VPS: git pull → `systemctl disable --now marketing-campaign-escalations.timer
   marketing-campaign-escalations.service` → rm unit files → daemon-reload.
5. Supabase SQL editor on **prod ref lzyvawfyrisuyikjsgtk** (the marketing
   tables live only there — no staging copy): run AUDIT selects in
   `migrations/fix_followup_templates.sql` (add
   `OR body_template LIKE '%days ago%'` to A1), row counts must match
   UPDATE counts, then COMMIT, then verify (expect 0 rows). Review A3's
   `outreach_campaigns.intro_body` hits by hand.
6. Re-enable `marketing-campaign-reminders.timer` + `marketing-campaign-wave1.timer`,
   watch first tick via journalctl.

**Blockers:** /lgtm is founder-only; SQL + VPS steps are Raghav-run.
