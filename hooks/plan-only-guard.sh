#!/usr/bin/env bash
# Plan-only guard (W32 retro, blocker #3) — warn-only, two-stage.
#
# The scar: "I never asked u to go and fix this... i just asked u to make a plan" → full
# revert (lt-price-checker, 2026-08-06). The user now types "DONT CODE" defensively in
# ~every planning request (8+ sessions in W32). The instruction is given at prompt time
# but forgotten by the time the model reaches for Edit/Write mid-plan.
#
# Stage 1 (UserPromptSubmit): if the prompt contains a plan-only phrase, drop a per-session
#   marker; any later prompt that instead greenlights building ("go", "start", "build",
#   "implement", "fix it", "do it") clears it. Unmatched prompts leave the marker alone —
#   short follow-ups ("A", "yes") during a planning discussion must not disarm the guard.
# Stage 2 (PreToolUse Edit|Write|NotebookEdit): if the marker is live and the target looks
#   like source code (not the plan/doc file itself), inject a hard reminder.
#
# Warn-only by design (exit 0 always) — plan mode is the real lock; this catches the
# sessions where plan mode wasn't engaged. Keep the phrase list tight: a hook that cries
# wolf trains the model to ignore hook context.
set -uo pipefail
input=$(cat)

event=$(printf '%s' "$input" | jq -r '.hook_event_name // ""' 2>/dev/null)
sid=$(printf '%s' "$input" | jq -r '.session_id // "nosession"' 2>/dev/null)
marker_dir="$HOME/.claude/tmp"
marker="$marker_dir/plan-only-$sid"

case "$event" in
  UserPromptSubmit)
    prompt=$(printf '%s' "$input" | jq -r '.prompt // ""' 2>/dev/null | head -c 4000)
    if printf '%s' "$prompt" | grep -qEi "don'?t code|dont code|do not code|no coding|no code changes|don'?t (write|make) any code|just (make )?(the |a )?plan|just scope|scope (it|this) out( for me)?|only discussion|just discussion|no coding changes|don'?t build|do not build|do ?n[o']?t exit plan mode"; then
      mkdir -p "$marker_dir" && : > "$marker"
      jq -cn '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:"PLAN-ONLY TURN: the user asked for a plan/scope/discussion and explicitly did NOT ask for code. Do not Edit or Write source files this turn — deliver the plan and stop. This constraint persists across turns until the user clearly says to build (e.g. go / start / implement / fix it)."}}'
      exit 0
    fi
    # Clear only on an explicit greenlight, not on any unmatched prompt.
    if printf '%s' "$prompt" | grep -qEi '^ *(go|start|proceed|do it|ship it|build( it)?|implement( it)?|fix it|apply it|execute|land it)\b|start (this|the) plan|execute (this|the) plan|start implementation|exit plan mode and'; then
      rm -f "$marker"
    fi
    ;;
  PreToolUse)
    [ -f "$marker" ] || exit 0
    # Stale-marker safety: sessions can end without a greenlight; ignore markers >12h old.
    if [ -n "$(find "$marker" -mmin +720 2>/dev/null)" ]; then rm -f "$marker"; exit 0; fi
    path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // ""' 2>/dev/null)
    [ -n "$path" ] || exit 0
    # Writing the plan/doc itself is the point of a planning turn — only warn on source code.
    printf '%s' "$path" | grep -qEi '\.(md|markdown|txt|json|canvas|html)$' && exit 0
    printf '%s' "$path" | grep -qEi '(^|/)(plans?|tasks|docs|notes)/' && exit 0
    jq -cn --arg p "$path" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:("STOP: this session is in a PLAN-ONLY state (the user said not to code, and has not yet said go). You are about to modify " + $p + ", which looks like source code. Unless the user has since clearly asked you to build, do not make this edit — finish the plan instead. A previous violation of this cost a full revert.")}}'
    ;;
esac
exit 0
