# Image Style Transfer Prompt Skill

## Overview
Create a skill that extracts the **style** from an input JSON prompt and helps the user create new images in that same style. The user provides a reference prompt, Claude extracts the style elements, asks what the user wants to create, then generates a new prompt combining the extracted style with the user's subject.

## Skill Details
- **Name**: `style-prompt-creator`
- **Location**: `~/.claude/skills/style-prompt-creator/SKILL.md`
- **Trigger phrases**: "create in this style", "use this style", "style transfer prompt", "generate like this"

## Workflow Design

### Phase 1: Style Extraction
- Accept JSON prompt as input
- Parse and **extract style elements only**:
  - Art style (photorealistic, illustration, anime, etc.)
  - Color palette and tones
  - Lighting and mood
  - Texture and detail level
  - Composition tendencies
  - Quality modifiers
- Present a summary: "This prompt has X style with Y lighting, Z color palette..."

### Phase 2: Question Session - What Do YOU Want to Create?
Ask the user about their new image:

**Subject:**
- What is the main subject of your new image?
- Any secondary elements or characters?

**Scene/Setting:**
- Where does this take place?
- Time of day / environment?

**Composition:**
- Desired framing (close-up, wide shot, etc.)?
- Any specific poses or arrangements?

**Style Tweaks (optional):**
- Any adjustments to the original style?
- Elements to emphasize or de-emphasize?

### Phase 3: Style Fusion
- Merge extracted style with user's subject/scene
- Ensure style elements are preserved
- Adapt composition style to new content
- Maintain consistency

### Phase 4: Output
Generate two versions:
1. **JSON format**: Structured object with style + new content
2. **Text prompt**: Ready-to-use prose version

## Files to Create

### 1. SKILL.md
```
~/.claude/skills/image-prompt-refiner/SKILL.md
```

Contains:
- YAML front matter (name, description with triggers)
- Workflow instructions
- Question templates
- Output format templates

## Verification
1. Invoke skill with `/image-prompt-refiner` or trigger phrase
2. Provide a sample JSON prompt
3. Answer the refinement questions
4. Verify output contains both JSON and text versions
5. Confirm refined prompt captures all discussed preferences
