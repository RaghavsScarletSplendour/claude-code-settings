---
name: style-prompt-creator
description: Extract style from a JSON image prompt and create new prompts in that style. Use when user wants to "create in this style", "use this style", "style transfer prompt", "generate like this", or provides a JSON prompt and wants to make similar images.
---

# Style Prompt Creator

Create new image prompts by extracting the style from an existing JSON prompt and applying it to your own subject/scene.

## Workflow

### Step 1: Receive and Analyze the Input Prompt

The user will provide a JSON prompt. Parse it and extract **style elements only**:

**Style Elements to Extract:**
- **Art Style**: photorealistic, illustration, anime, oil painting, watercolor, 3D render, etc.
- **Color Palette**: warm/cool tones, specific colors, saturation levels
- **Lighting**: natural, studio, dramatic, soft, golden hour, neon, etc.
- **Mood/Atmosphere**: dark, bright, dreamy, dramatic, serene, chaotic
- **Texture/Detail**: smooth, rough, highly detailed, minimalist
- **Quality Modifiers**: 8K, cinematic, masterpiece, professional, etc.
- **Composition Style**: symmetrical, rule of thirds, close-up tendency, wide shots

**Present a summary to the user:**
```
I've extracted the following style from your prompt:

- Art Style: [extracted style]
- Color Palette: [extracted colors/tones]
- Lighting: [extracted lighting]
- Mood: [extracted mood]
- Texture/Detail: [extracted detail level]
- Quality: [extracted quality modifiers]

Now let's create something new in this style!
```

### Step 2: Ask About the User's New Image

Ask questions to understand what they want to create. Use conversational questions, not a rigid form.

**Core Questions:**

1. **Subject**: "What would you like to be the main subject of your new image?"
   - Person, animal, object, landscape, abstract concept?
   - Any specific details about the subject?

2. **Scene/Setting**: "Where should this take place?"
   - Indoor/outdoor?
   - Specific location or environment?
   - Time of day?

3. **Composition**: "How should the image be framed?"
   - Close-up, medium shot, wide shot?
   - Any specific angle or perspective?
   - Portrait or landscape orientation?

4. **Additional Elements**: "Anything else to include?"
   - Secondary subjects?
   - Props or background elements?
   - Text or symbols?

5. **Style Adjustments** (optional): "Would you like to tweak the style at all?"
   - Keep exactly as extracted?
   - Modify any specific element?
   - Make it more/less intense?

### Step 3: Generate the Refined Prompt

Combine the extracted style with the user's subject/scene:

1. Take all extracted style elements
2. Merge with the user's described subject and scene
3. Ensure style keywords are preserved
4. Adapt composition style to fit new content
5. Maintain quality modifiers

### Step 4: Output Both Formats

Provide two versions:

**JSON Format:**
```json
{
  "subject": "[user's main subject with details]",
  "scene": "[user's scene/setting]",
  "style": {
    "artStyle": "[extracted art style]",
    "colorPalette": "[extracted colors]",
    "lighting": "[extracted lighting]",
    "mood": "[extracted mood]",
    "texture": "[extracted texture]"
  },
  "composition": "[user's framing + extracted tendencies]",
  "quality": "[extracted quality modifiers]",
  "additionalElements": "[any extras]"
}
```

**Text Prompt:**
```
[Subject description], [scene/setting], [art style], [lighting], [mood], [color palette], [texture/detail], [composition], [quality modifiers]
```

## Example Interaction

**User provides:**
```json
{
  "prompt": "A mystical forest at twilight, ethereal glow, soft purple and blue tones, fantasy illustration style, highly detailed foliage, magical atmosphere, 8K resolution, cinematic lighting"
}
```

**Claude extracts:**
- Art Style: Fantasy illustration
- Colors: Soft purple and blue tones
- Lighting: Cinematic, twilight, ethereal glow
- Mood: Magical, mystical atmosphere
- Detail: Highly detailed
- Quality: 8K resolution

**Claude asks:** "What would you like to create in this style?"

**User:** "A dragon perched on a mountain cliff"

**Claude asks:** "Any specific details about the dragon? And what's the setting - mountain peaks, cloudy sky?"

**User:** "Ancient dragon with crystalline scales, overlooking a vast valley, storm clouds gathering"

**Output JSON:**
```json
{
  "subject": "Ancient dragon with crystalline scales perched on mountain cliff",
  "scene": "Overlooking vast valley, storm clouds gathering",
  "style": {
    "artStyle": "Fantasy illustration",
    "colorPalette": "Soft purple and blue tones",
    "lighting": "Cinematic, ethereal glow",
    "mood": "Magical, mystical atmosphere",
    "texture": "Highly detailed"
  },
  "composition": "Wide shot, dramatic perspective",
  "quality": "8K resolution",
  "additionalElements": "Storm clouds, vast valley below"
}
```

**Output Text:**
```
Ancient dragon with crystalline scales perched on a mountain cliff, overlooking a vast valley with storm clouds gathering, fantasy illustration style, soft purple and blue tones, cinematic ethereal glow lighting, magical mystical atmosphere, highly detailed, wide dramatic perspective, 8K resolution
```

## Tips

- If the input JSON is minimal, ask the user to describe the style they're going for
- Be conversational, not robotic
- Confirm the extracted style before moving to questions
- Offer to iterate on the final prompt if needed
