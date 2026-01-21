---
description: Commit changes, push to remote, and create a pull request
allowed-tools: Bash(git:*), Bash(hub:* OR gh:*)  # Adjust based on your PR tool (gh for GitHub CLI, hub, etc.)
---

## Pre-fetched Context
- Git status: !`git status -s`
- Current branch: !`git branch --show-current`
- Staged diff: !`git diff --staged`
- Unstaged changes: !`git diff`
- Recent commits: !`git log --oneline -10`

## Task
1. Suggest a concise, conventional commit message based on the changes.
2. Stage all changes if needed (`git add .`).
3. Commit with the approved message.
4. Push to the remote branch.
5. Create a draft pull request (using `gh pr create` or equivalent) with a title and description summarizing the changes.

Ask for confirmation on the commit message and PR details before proceeding.
