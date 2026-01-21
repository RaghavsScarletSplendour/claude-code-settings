---
name: gemini-image-generator
description: Generate images using Gemini's Nano Banana Pro model via browser automation. Use when user invokes /generate-image with a JSON prompt, asks to "generate an image with Gemini", "use Nano Banana Pro", or wants to create images from a JSON prompt.
user_invocable:
  command: generate-image
  description: Generate an image with Gemini Nano Banana Pro from a JSON prompt
---

# Gemini Image Generator

Generate images by pasting a JSON prompt into Gemini with Nano Banana Pro selected.

**Target Platform:** Claude for Chrome (browser automation required)

## Arguments

The skill accepts a JSON prompt as an argument. This can be provided:
- Directly after the command: `/generate-image {"prompt": "...", ...}`
- In the conversation before invoking the skill

## Workflow

### Step 1: Get Browser Context

1. Call `tabs_context_mcp` with `createIfEmpty: true` to ensure a tab group exists
2. Create a new tab using `tabs_create_mcp` for the Gemini session

### Step 2: Navigate to Gemini

1. Navigate to `https://gemini.google.com` using the `navigate` tool
2. Wait for the page to load completely
3. Take a screenshot to verify the page loaded

### Step 3: Select Nano Banana Pro (Create Images)

1. Click "Tools" in the input area, OR click the "Create image" button with the banana icon
2. Select "Create images" from the dropdown - this IS Nano Banana Pro
3. Verify the "Image" tag appears next to the input field (with banana icon)
4. The model name "Nano Banana Pro" will be shown in the response header after generation

### Step 4: Enter the JSON Prompt

1. Find the chat input field using `find` or `read_page` tool
2. Click on the input field to focus it
3. Type or paste the JSON prompt into the input
4. Take a screenshot to verify the prompt is entered

### Step 5: Generate the Image

1. Find and click the send/submit button (or press Enter)
2. Wait briefly for the generation to begin
3. Task is complete - no further action required

## Safety Rules

- **Never navigate away** from gemini.google.com during the workflow
- If login is required, inform the user and wait for them to authenticate
- If CAPTCHA appears, inform the user
- Do not modify or alter the JSON prompt provided by the user

## Example Usage

**User:** `/generate-image {"prompt": "A serene mountain landscape at sunset", "style": "photorealistic"}`

**Workflow:**
1. Open new tab and navigate to gemini.google.com
2. Click model selector, choose Nano Banana Pro
3. Paste the JSON prompt into the chat
4. Click send to generate
5. Done
