# Session state — jdjones-human-resources-agent

updated: 2026-08-11T07:45:00Z

## ✅ LIVE. Worker running on the VPS against staging, connected mailbox `hrd@jdjones.com`. Setup complete.

**Verified live** (not assumed): `journalctl -u hr-inbound-worker` shows a clean
startup — `mailbox=hrd@jdjones.com scope=https://www.googleapis.com/auth/gmail.modify
supabase_project=ffrsffycrpevjhfyklxs mailbox_id=1ea1da92-ea01-4964-861c-f717d38d9599
delegated_sa=email-sender@jd-jones-order-management.iam.gserviceaccount.com` — every
HTTP request in the log is `200 OK`, zero errors, and it survived a real
`systemctl restart` cleanly (old process shut down gracefully mid-cycle, new one came
up and re-verified its own mailbox row). `mailbox_id` matches exactly the row this
session inserted into `connected_mailboxes` on staging.

**Full path to get here, for the record (real scars, useful if this ever needs
repeating for another mailbox/worker):**
1. PR #1 merged into `staging`, then `main` fast-forwarded to match (VPS runs off
   `main` for this repo — `staging` is a jdjones-platform-specific concept, Raghav
   corrected my wrong assumption mid-session).
2. **Address correction**: real mailbox is `hrd@jdjones.com`, not `hr@jdjones.com`
   (which every doc in both repos said, including this file's own first draft).
   Confirmed not hardcoded anywhere in real code, only in test fixtures — free fix.
3. `connected_mailboxes` row inserted directly on staging (`app='hr'`, `active=true`,
   `can_send=false` since the worker never sends, `can_receive=true`) —
   `id=1ea1da92-ea01-4964-861c-f717d38d9599`.
4. VPS clone/venv/install: `/opt/jdjones/human-resources-agent`, matching the
   `order-email-agent` convention on this same box.
5. `scripts/check_gmail_access.py` (NOT the old deleted `authorize_gmail.py`) confirmed
   the domain-wide-delegation Gmail grant genuinely works — real proof, not Raghav's
   recollection of having set it up.
6. Env file `/home/raghav/.hermes/hr-agent.env` (0600, deliberately separate from the
   shared `/home/raghav/.hermes/.env` which points every other worker at PROD — this
   worker needs staging). **Real trap hit and fixed**: the first `SUPABASE_SECRET_KEY`
   value pasted in was actually the Supabase **database password** (from Settings →
   Database), not the API secret key (Settings → API) — wrong page, easy mix-up.
   Caught via a live `curl` test against the REST API (401 → bad key, confirmed) rather
   than trusting "I pasted it." Second attempt with the real `service_role`/`sb_secret_`
   key from Settings → API tested 200 and worked.
7. `systemd/hr-inbound-worker.service` installed + `enable --now` + restarted after the
   key fix — clean startup confirmed live in `journalctl`.
8. **Both Gmail labels confirmed set up**, live-checked via `check_gmail_access.py`:
   `JDJ/HR/AI` was auto-created by the worker itself on its first cycle (it does this
   every cycle, not a one-time thing). `JDJ/HR/Manual` — the label a human applies by
   hand to rescue a CV the AI missed — is NEVER created by the worker on purpose (it's
   only ever allowed to read that label, never write it), so it had to be created once,
   manually: ran `gmail_client.ensure_label(service, 'JDJ/HR/Manual')` directly (the
   same tested function the worker itself uses for its own label) via the VPS's already-
   proven credentials. Created successfully, `Label_2`. **Real gotcha hit along the
   way**: sourcing the plain `KEY=value` env file with a bare `source file.env` sets
   shell variables but does NOT export them to child processes like Python — worked fine
   for `curl` (shell expands `$VAR` inline) but not for the Python script, which reads
   `os.environ`. Fix: `set -a; source file.env; set +a`. Doesn't affect the systemd
   service itself — `EnvironmentFile=` reads the file directly, unrelated mechanism.

**Not yet done, optional next milestone**: send a real CV to `hrd@jdjones.com` and
watch it land in the HR app's queue (`/hr` in jdjones-platform, staging) — that's the
true end-to-end proof, one level past "the worker starts cleanly." Nobody has done
this yet. Both labels a human/the AI would need for that flow now exist, so this is
unblocked whenever someone wants to try it.

**Blockers:** none. This phase is done, including the label setup.
