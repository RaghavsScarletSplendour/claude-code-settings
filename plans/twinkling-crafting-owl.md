# AI Art Prompting Skill Plan

## Overview

Create an orchestrator skill for generating AI art prompts and optionally executing them via Google Veo3 in Chrome.

## Skill vs Agent Decision

**Recommendation: Skill** (not an agent)

| Factor | Skill | Agent |
|--------|-------|-------|
| Procedural workflow | Yes - step-by-step prompt crafting | No - more persona-based |
| Slash command access | `/ai-art` directly invocable | Requires mention or context |
| Browser automation | Full support via Chrome tools | Same |
| Reference files | Can include prompt templates, style guides | Same |
| Focused scope | Perfect for specific task | Better for broad expertise |

A **skill** is ideal because this is a defined workflow:
1. Gather user's vision
2. Apply prompt engineering techniques
3. Craft the prompt
4. (Optional) Execute in Veo3 via Chrome

## Skill Structure

```
~/.claude/skills/ai-art-prompter/
├── SKILL.md                    # Main skill definition
└── references/
    ├── prompt-formulas.md      # Prompt structures and patterns
    ├── style-modifiers.md      # Artistic styles, lighting, cameras
    └── veo3-guide.md           # Veo3-specific syntax and tips
```

## Core Prompt Engineering Components

Based on AI art best practices, prompts should include:

1. **Subject** - Main focus (person, object, scene)
2. **Style** - Art movement, artist influence, medium
3. **Composition** - Framing, perspective, layout
4. **Lighting** - Type, direction, mood
5. **Color palette** - Tones, saturation, harmony
6. **Quality modifiers** - Resolution, detail level
7. **Negative prompts** - What to avoid (for supported tools)

## Workflow Design

### Phase 1: Vision Gathering
- Ask user what they want to create
- Clarify style preferences
- Identify target platform (Veo3, Midjourney, DALL-E, etc.)

### Phase 2: Prompt Construction
- Apply appropriate formula for the platform
- Layer modifiers systematically
- Balance specificity with creative freedom

### Phase 3: Refinement
- Present draft prompt to user
- Offer variations (more cinematic, more abstract, etc.)
- Allow iterative tweaking

### Phase 4: Execution (Optional)
- If Veo3 selected and Chrome available:
  - Navigate to Veo3
  - Input the crafted prompt
  - Guide user through generation

## Open Questions

- [ ] Which AI art platforms to support? (Veo3, Midjourney, DALL-E, Stable Diffusion, Flux?)
- [ ] Should it specialize in video (Veo3) or images or both?
- [ ] Interactive refinement or one-shot prompt generation?
- [ ] Should it save prompt history/favorites?

## Files to Create

1. `~/.claude/skills/ai-art-prompter/SKILL.md`
2. `~/.claude/skills/ai-art-prompter/references/prompt-formulas.md`
3. `~/.claude/skills/ai-art-prompter/references/style-modifiers.md`
4. `~/.claude/skills/ai-art-prompter/references/veo3-guide.md`

## Verification

1. Invoke skill with `/ai-art`
2. Test prompt generation for different styles
3. Test Veo3 browser automation (requires Chrome extension)
