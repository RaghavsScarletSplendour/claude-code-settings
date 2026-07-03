#!/usr/bin/env bash
# Warn-only PreToolUse reminder — before a migration or WRITE/DDL SQL against a
# prod/shared DB, spawn database-reviewer to review the statement first.
# apply_migration -> always; execute_sql -> only when the query is a write/DDL.
# Never blocks: emits additionalContext, exit 0.
input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null)
remind=0
case "$tool" in
  *apply_migration) remind=1 ;;
  *execute_sql)
    q=$(printf '%s' "$input" | jq -r '.tool_input.query // .tool_input.sql // ""' 2>/dev/null)
    printf '%s' "$q" | grep -iqE '\b(insert|update|delete|create|alter|drop|truncate|grant|revoke)\b' && remind=1
    ;;
esac
[ "$remind" = 1 ] || exit 0
jq -cn '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:"Reminder: this is a migration or write/DDL SQL. Per CLAUDE.md, spawn the database-reviewer agent to review the statement BEFORE executing it against a production or shared DB (WHERE/UPDATE scope, revert safety, constraints, indexing, lock order)."}}'
exit 0
