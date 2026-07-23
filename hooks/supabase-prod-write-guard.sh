#!/usr/bin/env bash
# PreToolUse GUARD — every Supabase WRITE against PROD requires your real,
# interactive approval. Reads are never touched, on any project, ever.
#
# v2 — replaces the v1 "deny + self-serve override" design. A security review
# (and a direct repro) found the v1 override was a hole: `touch
# ~/.claude/.prod-write-ok` — an ordinary, already-allowed Bash call — silently
# cleared the block, so the agent could self-authorize the exact thing this
# hook exists to gate. v2 removes that override entirely. There is no env var,
# no sentinel file, no in-script escape hatch. The only way a prod write
# proceeds is a live "ask" permission decision that only the human can answer.
#
# POLICY (explicit, from the user): reads never need approval, anywhere,
# including on prod. WRITES to PROD need approval every single time, no
# exceptions. Staging and every other ref are unaffected by this hook — they
# still just get the existing warn-only supabase-write-reminder.sh.
#
# DETECTION FIX: v1 scanned for a denylist of write verbs and missed COPY,
# CALL, function calls that write, SELECT ... INTO, REFRESH MATERIALIZED VIEW.
# v2 flips the polarity: a statement must be PROVABLY a pure read (starts with
# SELECT/EXPLAIN/SHOW/WITH AND contains no write verb anywhere in the text —
# catches a modifying CTE or a stacked statement after a semicolon) to be let
# through untouched. Anything else on prod — unrecognized shapes included —
# is treated as a write and requires approval.
#
# HONEST LIMIT: this file, like anything under ~/.claude, can be edited or
# deleted by an agent with Bash/Edit access — no hook here can gate edits to
# itself. This is not a sandboxed boundary against a fully adversarial or
# self-modifying agent. What it does do: turn "the agent decided to proceed"
# into "the human had to click approve," which is the actual failure mode
# that motivated it.
set -uo pipefail

PROD_REF="lzyvawfyrisuyikjsgtk"      # jdjones-agents = PROD (names mislead)
STAGING_REF="ffrsffycrpevjhfyklxs"   # JD Jones Test Server = migration target

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null)
ref=$(printf '%s' "$input" | jq -r '.tool_input.project_id // .tool_input.project_ref // ""' 2>/dev/null)

# Out of scope entirely unless it's one of the two Supabase write-capable tools.
case "$tool" in
  *apply_migration|*execute_sql) : ;;
  *) exit 0 ;;
esac

# A ref that's present and clearly NOT prod is out of scope (falls through to
# the warn-only reminder). An EMPTY/unreadable ref on one of these tools is
# NOT waved through — we can't prove it isn't prod, so it stays in scope below.
if [ -n "$ref" ] && [ "$ref" != "$PROD_REF" ]; then
  exit 0
fi

is_write=0
case "$tool" in
  *apply_migration)
    is_write=1
    ;;
  *execute_sql)
    q=$(printf '%s' "$input" | jq -r '.tool_input.query // .tool_input.sql // ""' 2>/dev/null)
    qtrim=$(printf '%s' "$q" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
    if printf '%s' "$qtrim" | grep -qiE '^(select|explain|show|with)\b' \
       && ! printf '%s' "$q" | grep -qiE '\b(insert|update|delete|drop|alter|create|truncate|grant|revoke|copy|call|refresh|merge|into)\b'
    then
      is_write=0   # provably a pure read
    else
      is_write=1   # anything else — including unrecognized shapes — needs approval
    fi
    ;;
esac
[ "$is_write" = 1 ] || exit 0

reason="WRITE against PROD ($PROD_REF). This needs your explicit approval in the permission prompt — every time, no exceptions, no override coded into this script. Before approving: prefer a staging ($STAGING_REF) dry-run first, and consider a database-reviewer pass. If you don't see an approval prompt for this, stop and tell Raghav directly rather than proceeding — that would mean this mechanism isn't being honored."

jq -cn --arg r "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "ask",
    permissionDecisionReason: $r
  }
}'
exit 0
