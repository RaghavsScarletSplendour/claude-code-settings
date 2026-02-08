---
name: archive-prd
description: "Archive completed PRD work to memory. Use when finished with a feature, clearing prd files, or archiving progress. Triggers on: archive prd, clear prd, archive progress, move to memory archive, add to archive."
user_invocable:
  command: archive-prd
  description: Archive prd.md, prd.json, and progress.txt to tasks/archive/
---

# Archive PRD Skill

Archives completed PRD work (prd.md, prd.json, progress.txt) to the memory archive folder and resets active files.

---

## Steps

### 1. Read progress.txt and Extract Feature Name

Read `progress.txt` and find the feature name from the first iteration header.

**Pattern to look for:**
```
## Iteration 1 - US-001: [description]
```

**Extract feature name logic:**
- If progress.txt has iteration content, derive feature name from the work description
- Common patterns: "Extract X to Y" → "extract-x", "Add X feature" → "x-feature", "Refactor X" → "x-refactor"
- If unclear, ask the user what feature name to use
- Convert to kebab-case (lowercase, hyphens)

**If progress.txt is empty (just the template header):**
- Ask the user what feature name to use for the archive

### 2. Determine Next Version Number

List `tasks/archive/` directory and find existing `vN-*` folders.

```bash
ls tasks/archive/ | grep '^v[0-9]' | sort -V
```

**Find the highest version number and increment by 1.**

Example:
- Existing: `v1-mvp`, `v2-dry-refactor`
- Next version: `v3`

### 3. Create Archive Folder

Create the new archive folder:
```
tasks/archive/vN-feature-name/
```

Example: `tasks/archive/v3-auth-cleanup/`

### 4. Copy Files to Archive

Copy these files to the archive folder:

| Source | Destination | Condition |
|--------|-------------|-----------|
| `progress.txt` | archive folder | Always (if has content beyond template) |
| `tasks/prd.md` | archive folder | If exists and not empty template |
| `tasks/prd.json` | archive folder | If exists and not empty template |
| `tasks/prd-*.md` | archive folder | Any matching files |

**Use bash to copy:**
```bash
cp progress.txt tasks/archive/vN-feature-name/
cp tasks/prd.md tasks/archive/vN-feature-name/ 2>/dev/null || true
cp tasks/prd.json tasks/archive/vN-feature-name/ 2>/dev/null || true
cp tasks/prd-*.md tasks/archive/vN-feature-name/ 2>/dev/null || true
```

### 5. Reset Active Files to Empty Templates

**Reset progress.txt:**
```markdown
# Progress Log

<!-- Ralph Loop progress will be logged here -->

```

**Reset tasks/prd.md (if it existed):**
```markdown
# PRD: [Feature Name]

<!-- Feature PRD will go here -->

```

**Reset tasks/prd.json (if it existed):**
```json
{
  "project": "",
  "branchName": "",
  "description": "",
  "userStories": []
}
```

### 6. Confirm Completion

Tell the user:
- What archive folder was created
- What files were archived
- That active files have been reset

---

## Example Output

```
Archived to tasks/archive/v3-dry-refactor/:
- progress.txt (50 iterations)
- prd.md
- prd.json
- prd-codebase-dry-refactor.md

Reset active files:
- progress.txt (empty template)
- tasks/prd.md (empty template)
- tasks/prd.json (empty template)
```

---

## Edge Cases

1. **No progress content**: Ask user for feature name before archiving
2. **No tasks/prd.md or prd.json**: Skip those files, still archive progress.txt
3. **Archive folder already exists**: Add suffix like `v3-feature-name-2`
4. **User wants custom name**: Allow user to override auto-detected name
