# Plan: Create Gemini Image Generation Skill

## Overview
Create a skill that generates images using Gemini's Nano Banana Pro model via browser automation.

## Skill Details
- **Name:** `gemini-image-generator`
- **Command:** `/generate-image`
- **Location:** `/Users/raghavbajoria/.claude/skills/gemini-image-generator/`

## Files to Create

### 1. `SKILL.md` - Main skill definition
```
skills/gemini-image-generator/
└── SKILL.md
```

## Skill Workflow

1. **Receive JSON prompt** as argument to the skill
2. **Open browser** and navigate to `gemini.google.com`
3. **Select model:** Click the model selector and choose "Nano Banana Pro"
4. **Paste prompt:** Enter the JSON prompt into the Gemini chat input
5. **Generate:** Send the message to generate the image
6. **Complete:** Task is done (no further action needed per user request)

## SKILL.md Content Structure

```markdown
---
name: gemini-image-generator
description: Generate images using Gemini's Nano Banana Pro model. Use when user invokes /generate-image with a JSON prompt.
---

# Gemini Image Generator

Generate images by pasting a JSON prompt into Gemini with Nano Banana Pro selected.

## Workflow

### Step 1: Get Browser Context
- Call tabs_context_mcp to get current tab state
- Create a new tab for Gemini

### Step 2: Navigate to Gemini
- Navigate to https://gemini.google.com

### Step 3: Select Nano Banana Pro
- Click the model selector
- Select "Nano Banana Pro" from the options

### Step 4: Enter Prompt
- Find the chat input field
- Paste the JSON prompt
- Send the message

### Step 5: Complete
- Wait for image generation to begin
- Task complete (no further action required)
```

## Verification
1. Create the skill directory and SKILL.md file
2. Test by running `/generate-image` with a sample JSON prompt
3. Verify the skill navigates to Gemini, selects the model, and submits the prompt
