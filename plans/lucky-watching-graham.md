# Gemini Image Prompt Extractor Skill

## Overview
Create a skill that takes an image from the chat, uploads it to Google Gemini via Chrome, and asks Gemini to analyze the image and return a JSON prompt suitable for recreating the image with an AI image generator.

## File to Create
`/Users/raghavbajoria/.claude/skills/gemini-image-prompter/SKILL.md`

## Complete SKILL.md Content

```markdown
---
name: gemini-image-prompter
description: Extract image generation prompts from images using Google Gemini. Use when user provides an image and asks to "get the prompt", "extract prompt", "what prompt would create this", "reverse engineer this image", "describe this for image generation", or "analyze this image for a prompt". Requires Claude for Chrome browser automation.
---

# Gemini Image Prompt Extractor

Extract image generation prompts from user-provided images by uploading them to Google Gemini and requesting a structured JSON analysis.

**Target Platform:** Claude for Chrome (browser automation required)

## Prerequisites

- User must provide an image in the chat (screenshot or uploaded file)
- Chrome browser with Claude for Chrome extension active
- User should be logged into Google (for Gemini access)

## Workflow

### Step 1: Initialize Browser Session

1. Call `tabs_context_mcp` to get current browser context
2. Create a new tab with `tabs_create_mcp`
3. Navigate to `https://gemini.google.com`
4. Take a screenshot to verify the page loaded
5. If login is required, inform the user and wait for them to log in

### Step 2: Upload the Image

1. Find the image attachment button (usually a "+" or image icon near the input)
2. Use `upload_image` tool with:
   - `imageId`: The ID of the user's screenshot/image from the chat
   - `tabId`: The current Gemini tab
   - Either `ref` (for file input) or `coordinate` (for drag-drop area)
3. Verify the image appears in the chat input area

### Step 3: Send the Analysis Request

Type the following prompt in Gemini's input field:

```
Analyze this image and create a JSON prompt that could be used to recreate it with an AI image generator. Include these fields:

{
  "subject": "main subject/focal point of the image",
  "style": "artistic style (photorealistic, anime, oil painting, digital art, etc.)",
  "lighting": "lighting conditions and mood",
  "composition": "framing, perspective, and arrangement",
  "colors": "dominant color palette",
  "atmosphere": "overall mood and feeling",
  "details": "notable specific details worth preserving",
  "prompt": "complete prompt combining all elements into one cohesive description"
}

Return ONLY the JSON object, no additional explanation.
```

Submit the message by pressing Enter or clicking the send button.

### Step 4: Extract the Response

1. Wait 3-5 seconds for Gemini to generate the response
2. Take a screenshot to see the response
3. Use `get_page_text` or `read_page` to extract the JSON response
4. Parse and validate the JSON structure
5. Return the JSON prompt to the user

## Output Format

Present the extracted JSON to the user in a code block:

```json
{
  "subject": "...",
  "style": "...",
  "lighting": "...",
  "composition": "...",
  "colors": "...",
  "atmosphere": "...",
  "details": "...",
  "prompt": "..."
}
```

## Safety Rules

- Never navigate away from gemini.google.com during the process
- If CAPTCHA or additional verification is required, inform the user
- Do not store or transmit the image to any other service
- Only read the Gemini response, do not interact with other page elements

## Example Usage

**User:** [provides an image] Get the prompt for this image

**Workflow:**
1. Open Chrome, navigate to gemini.google.com
2. Upload the user's image
3. Send the JSON prompt analysis request
4. Wait for and extract Gemini's response
5. Return the JSON to the user

**Output:**
```json
{
  "subject": "A golden retriever puppy playing in autumn leaves",
  "style": "photorealistic, natural photography",
  "lighting": "warm afternoon sunlight, golden hour",
  "composition": "eye-level shot, shallow depth of field, puppy centered",
  "colors": "warm oranges, yellows, golden browns, green undertones",
  "atmosphere": "playful, joyful, cozy autumn feeling",
  "details": "individual leaves in motion, fur texture visible, bright eyes",
  "prompt": "Photorealistic image of a golden retriever puppy playing joyfully in a pile of autumn leaves, warm golden hour lighting, shallow depth of field, vibrant orange and yellow fall colors, eye-level perspective, detailed fur texture, leaves caught in motion"
}
```
```

## Verification
1. Provide any test image in the Claude Code chat
2. Say "get the prompt for this image" or "extract prompt"
3. The skill should:
   - Open Chrome and navigate to Gemini
   - Upload the image
   - Request the JSON analysis
   - Return the extracted JSON prompt
