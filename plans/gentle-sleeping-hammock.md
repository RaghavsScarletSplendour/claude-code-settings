# Landing Page Animation Plan: "Noise → Signal"

## Concept Summary
A short animation showing chaotic, Matrix-style glitch text that suddenly snaps into a clean logo + tagline. Visual metaphor for "cutting through the noise to focus on one thing."

---

## Animation Specification

### Phase 1: Chaos (2-3 seconds)
- **Visual**: Matrix-style random characters floating/drifting across the screen
- **Effect**: RGB chromatic aberration (red/green/blue channel separation creating that "hacker movie" color split)
- **Motion**: Jittery, glitchy, constantly shifting
- **Background**: Dark or neutral (contrasts with final cream)
- **Text**: Random unreadable characters, not real words

### Transition
- **Type**: Sudden snap (hard cut, instant)
- **No fade or gradual transition**

### Phase 2: Signal (holds indefinitely)
- **Background**: Cream paper (#f5f2e9)
- **Logo**: "Focus First" in IBM Plex Mono
- **Color**: Dark ink (#1a1a1a)
- **Tagline**: Something like "Learn one thing today" or "Cut through the AI hype"
- **Style**: Clean, minimal, lots of whitespace

### Looping Behavior
- One-shot animation (no loop)
- Ends on the logo frame

---

## Frame Creation Guide (for you)

When creating frames in your design tool:

1. **Glitch frames** (~10-15 frames)
   - Each slightly different random character positions
   - RGB split offset varies per frame
   - Jitter/shake the positions slightly

2. **Final frame** (1 frame, holds)
   - Clean cream background
   - Centered "Focus First" text
   - Tagline below
   - Matches your existing app aesthetic

3. **Frame rate suggestion**: 12-15 fps for glitch (gives that choppy, digital feel)

---

## Next Step
You create the frames, then bring them back. I'll implement the animation using those frames with Framer Motion or CSS animations.
