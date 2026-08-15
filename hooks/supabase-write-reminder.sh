#!/usr/bin/env bash
# PreToolUse gate — apply_migration ALWAYS asks (hard "ask" decision, every
# ref, not just prod) and the ask reason mandates a database-reviewer pass
# first. This is what makes the migration audit actually fire instead of
# being a skippable text note.
# execute_sql write/DDL stays warn-only (additionalContext, never blocks) —
# the user only asked for the migration path to be a real gate.
input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null)

case "$tool" in
  *apply_migration)
    reason="Migration audit required before this applies. Spawn the database-reviewer agent now to review the migration statement (WHERE/UPDATE scope, revert safety, constraints, indexing, lock order) if you have not already done so for this exact migration in this turn. Once reviewed, proceed and this prompt will ask you (Raghav) to approve the apply — that approval is expected and fine, this hook does not deny."
    jq -cn --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
    exit 0
    ;;
  *execute_sql)
    q=$(printf '%s' "$input" | jq -r '.tool_input.query // .tool_input.sql // ""' 2>/dev/null)
    if printf '%s' "$q" | grep -iqE '\b(insert|update|delete|create|alter|drop|truncate|grant|revoke)\b'; then
      jq -cn '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:"Reminder: this is write/DDL SQL. Per CLAUDE.md, spawn the database-reviewer agent to review the statement BEFORE executing it against a production or shared DB (WHERE/UPDATE scope, revert safety, constraints, indexing, lock order)."}}'
    fi
    exit 0
    ;;
esac
exit 0
