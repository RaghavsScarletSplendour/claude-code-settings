---
name: reddit-helper
description: Automatically find posts to reply to on Reddit and draft helpful replies. Use when user wants to engage on Reddit, build karma, or do pre-launch warm-up. Triggers on "/reddit-helper" or requests to "help me engage on Reddit".
user_invocable:
  command: reddit-helper
  description: Find Reddit posts and draft replies for approval
---

# Reddit Auto-Helper

Automate Reddit engagement by finding the best posts to reply to and drafting helpful replies for your approval.

**Target Platform:** Claude for Chrome (browser automation required)

## Arguments

The skill accepts these arguments:

```
/reddit-helper <subreddits> --persona "<help type>"
```

- **subreddits**: Comma-separated list of subreddits (with or without r/ prefix)
- **--persona**: Your expertise/tone for replies (in quotes)

**Example:**
```
/reddit-helper r/MachineLearning,r/LocalLLaMA,r/learnmachinelearning,r/artificial,r/SideProject --persona "AI enthusiast who builds learning tools and loves helping others understand ML concepts"
```

If no arguments provided, ask the user for:
1. Which 5 subreddits to engage in
2. What persona/expertise to use when replying

## Workflow

### Step 1: Get Browser Context

1. Call `tabs_context_mcp` with `createIfEmpty: true` to ensure a tab group exists
2. Create a new tab using `tabs_create_mcp` for the Reddit session
3. Store the tab ID for all subsequent operations

### Step 2: Verify Reddit Login

1. Navigate to `https://www.reddit.com`
2. Take a screenshot to verify the page loaded
3. Check if user is logged in (look for username in top-right or profile icon)
4. **If not logged in:** Inform the user and wait for them to log in manually. Do NOT attempt to log in.
5. Once logged in, proceed to Step 3

### Step 3: Process Each Subreddit

For each of the 5 subreddits, perform Steps 3a-3e (goal: 2 replies per subreddit, 10 total)

#### Step 3a: Navigate to Subreddit

1. Navigate to `https://www.reddit.com/r/[subreddit]/new/` (start with New posts)
2. Wait for page to load
3. Take a screenshot to verify you're on the right subreddit

#### Step 3b: Scan for Good Posts

Read the page using `read_page` or `get_page_text` to find posts. Look for:

**Good targets (prioritize these):**
- Questions asking for help or advice
- Requests for recommendations
- Discussions where you can add genuine value
- New posts with 0-5 comments (easier to get noticed)
- Posts matching the user's persona/expertise

**Avoid these:**
- Already well-answered posts (10+ thoughtful comments)
- Promotional or self-promotional posts
- Controversial/political topics
- Posts older than 24 hours
- Locked or archived posts

#### Step 3c: Select 2 Best Posts

From the scanned posts, identify the 2 best opportunities where:
- The persona can provide genuine, helpful input
- The post hasn't been over-answered
- Your reply would add real value

If New doesn't have good options, also check:
- `https://www.reddit.com/r/[subreddit]/rising/`
- `https://www.reddit.com/r/[subreddit]/hot/` (look for recent posts)

#### Step 3d: Draft Reply (REQUIRES USER APPROVAL)

For each selected post:

1. Click on the post to open it
2. Read the full post content and any existing comments
3. Draft a helpful reply that:
   - Matches the specified persona
   - Directly addresses what the poster is asking
   - Provides genuine value (not generic advice)
   - Sounds natural and human (not AI-generated)
   - Is appropriately concise (2-4 paragraphs max)
   - Does NOT promote any product unless the post is explicitly asking for tool recommendations

4. **CRITICAL: Present the draft to the user:**
   ```
   SUBREDDIT: r/[subreddit]
   POST: "[Post title]"
   POST URL: [link]

   DRAFT REPLY:
   ---
   [Your drafted reply here]
   ---

   Should I post this reply? (yes/no/edit)
   ```

5. Wait for user response:
   - **"yes"** or **"y"**: Proceed to post
   - **"no"** or **"n"**: Skip this post, move to next
   - **"edit: [changes]"**: Revise the reply and show again
   - Any other feedback: Incorporate and show revised draft

#### Step 3e: Post the Reply (Only After Approval)

1. Find the comment/reply input box
2. Click to focus the input
3. Type the approved reply text
4. Find and click the "Comment" or "Reply" button
5. Wait briefly for the comment to post
6. Take a screenshot to confirm it posted successfully
7. **Wait 30-60 seconds before the next reply** (respect rate limits)

### Step 4: Move to Next Subreddit

After completing 2 replies in a subreddit:
1. Inform the user: "Completed r/[subreddit] (2/2 replies). Moving to r/[next subreddit]..."
2. Repeat Steps 3a-3e for the next subreddit

### Step 5: Summary Report

After all subreddits are processed, provide a summary:

```
REDDIT ENGAGEMENT SUMMARY
=========================
Total replies posted: X/10

r/MachineLearning:
  - [Post title 1] - [link]
  - [Post title 2] - [link]

r/LocalLLaMA:
  - [Post title 1] - [link]
  - [Post title 2] - [link]

[Continue for all subreddits]

Skipped: X posts (user declined)
```

## Safety Rules

- **NEVER post without explicit user approval** - Always show draft and wait for "yes"
- **NEVER attempt to log in** - User must already be logged in
- **NEVER upvote or downvote** automatically
- **NEVER navigate away** from reddit.com
- **NEVER post promotional content** unless explicitly approved for that specific post
- If CAPTCHA appears, inform the user and wait
- If rate-limited, inform the user and suggest waiting
- Respect the 30-60 second delay between replies
- If a subreddit is private or restricted, skip it and inform the user

## Troubleshooting

**"I can't find good posts"**
- Try the Rising tab instead of New
- Lower standards slightly (posts with up to 10 comments are okay)
- Inform user if a subreddit seems inactive

**"Reddit is showing a login page"**
- Stop and inform the user
- Wait for them to log in manually
- Resume once they confirm they're logged in

**"Comment didn't post"**
- Take a screenshot to diagnose
- Check for error messages
- May need to wait longer between comments (rate limit)

## Example Session

**User:** `/reddit-helper r/learnmachinelearning,r/MachineLearning --persona "ML engineer who enjoys explaining concepts simply"`

**Workflow:**
1. Open Reddit in browser
2. Navigate to r/learnmachinelearning/new
3. Find post: "Confused about attention mechanism in transformers"
4. Draft helpful explanation of attention
5. Show draft to user, get approval
6. Post reply, wait 45 seconds
7. Find another good post, repeat
8. Move to r/MachineLearning
9. Continue until 4 replies posted (2 per subreddit)
10. Show summary with links to all replies
