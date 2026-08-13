#!/bin/bash
# Re-injects the ASD-STE100 output-style rule on every user turn.
# CLAUDE.md alone decays out of attention in long conversations; this hook
# restates the rule fresh each turn so it keeps being followed.
jq -n --arg event UserPromptSubmit '{
  hookSpecificOutput: {
    hookEventName: $event,
    additionalContext: "OUTPUT STYLE — MANDATORY, every reply: write your visible text in ASD-STE100 (Simplified Technical English). Short sentences, under 20 words each. One idea per sentence. Active voice, present tense. No jargon or acronyms unless the user used them first. Steps as a numbered list, not prose. This governs your prose reply only — not code, file contents, or quoted user text."
  }
}'
