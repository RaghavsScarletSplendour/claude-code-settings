# Plan: Reddit Auto-Helper Skill

## Overview
Create a Claude Code skill `/reddit-helper` that automates Reddit engagement by finding posts to reply to and drafting helpful replies for user approval.

## Skill Location
`/Users/raghavbajoria/.claude/skills/reddit-helper/SKILL.md`

## Command Syntax
```
/reddit-helper <subreddits> --persona "<help type>"
```

Example:
```
/reddit-helper r/MachineLearning,r/LocalLLaMA,r/learnmachinelearning,r/artificial,r/SideProject --persona "AI enthusiast who builds learning tools"
```

## Skill Behavior

### Input Parameters
- **subreddits**: Comma-separated list of 5 subreddits
- **persona**: Description of what type of help to give (expertise area, tone)

### Workflow

1. **Get Browser Context**
   - Call `tabs_context_mcp` with `createIfEmpty: true`
   - Create new tab for Reddit session

2. **For Each Subreddit (5 total)**:

   a. **Navigate to Subreddit**
      - Go to `reddit.com/r/[subreddit]`
      - Take screenshot to verify

   b. **Browse for Good Posts**
      - Check "New" or "Rising" tab first
      - Look for: questions, help requests, discussions needing input
      - Avoid: promotional posts, already well-answered posts, old posts

   c. **Select 2 Best Posts**
      - Posts where the persona can add genuine value
      - Posts with few or no replies preferred

   d. **Draft Reply (for each post)**
      - Read the post content
      - Draft a helpful reply matching the persona
      - **Show draft to user for approval**
      - Wait for user confirmation before posting

   e. **Post Reply (if approved)**
      - Click reply/comment
      - Enter the approved text
      - Submit

3. **Summary**
   - Report which subreddits were covered
   - List posts replied to (with links)

### Safety Rules
- Never post without user approval
- Never upvote/downvote automatically
- Never navigate away from reddit.com
- If login required, inform user and wait
- If CAPTCHA appears, inform user
- Respect rate limits (brief waits between replies)

## Files to Create

### 1. Main Skill File
**Path:** `/Users/raghavbajoria/.claude/skills/reddit-helper/SKILL.md`

**Frontmatter:**
```yaml
---
name: reddit-helper
description: Automatically find posts to reply to on Reddit and draft helpful replies. Use when user wants to engage on Reddit, build karma, or do pre-launch warm-up. Triggers on "/reddit-helper" or requests to "help me engage on Reddit".
user_invocable:
  command: reddit-helper
  description: Find Reddit posts and draft replies for approval
---
```

**Body:** Full workflow instructions as outlined above

## Verification
1. Run `/reddit-helper r/SideProject --persona "indie developer"`
2. Verify it navigates to Reddit correctly
3. Verify it finds appropriate posts
4. Verify it shows draft replies before posting
5. Verify it waits for approval before each post
