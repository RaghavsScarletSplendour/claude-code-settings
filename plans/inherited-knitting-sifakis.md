# Plan: Version Control ~/.claude/ Skills & Agents on GitHub

## Current Inventory
**Location:** `~/.claude/` (`/Users/raghavbajoria/.claude/`)

### Existing Skills (6)
| Skill | Purpose |
|-------|---------|
| china-product-researcher | Research suppliers from Made-in-China, Alibaba, 1688 |
| code-principles-reviewer | Review code against SOLID, DRY, KISS principles |
| gemini-image-generator | Generate images via Gemini Nano Banana Pro |
| gemini-image-prompter | Extract prompts from images using Gemini |
| reddit-helper | Find Reddit posts and draft replies |
| style-prompt-creator | Extract & transfer image generation styles |

### Existing Agents (43 across 9 departments)
- **Engineering (7):** ai-engineer, backend-architect, devops-automator, frontend-developer, mobile-app-builder, rapid-prototyper, test-writer-fixer
- **Design (6):** brand-guardian, style-remix-generator, ui-designer, ux-researcher, visual-storyteller, whimsy-injector
- **Marketing (7):** app-store-optimizer, content-creator, growth-hacker, instagram-curator, reddit-community-builder, tiktok-strategist, twitter-engager
- **Product (3):** feedback-synthesizer, sprint-prioritizer, trend-researcher
- **Project Management (3):** experiment-tracker, project-shipper, studio-producer
- **Studio Operations (5):** analytics-reporter, finance-tracker, infrastructure-maintainer, legal-compliance-checker, support-responder
- **Testing (5):** api-tester, performance-benchmarker, test-results-analyzer, tool-evaluator, workflow-optimizer
- **Bonus (2):** joker, studio-coach
- **Standalone (5):** china-product-orchestrator, china-product-worker, frontend-developer, mobile-app-builder, security-auditor

---

## Goals
1. Create `.gitignore` to exclude runtime/cache data
2. Initialize git repo in `~/.claude/`
3. Push to private GitHub repository (`claude-skills-agents`)

---

## Implementation Steps

### Step 1: Create `.gitignore` in ~/.claude/
Exclude runtime data that shouldn't be version controlled:

```gitignore
# Runtime & Cache
cache/
paste-cache/
file-history/
shell-snapshots/
session-env/
debug/
ide/
statsig/
telemetry/
todos/
plugins/
projects/

# History & Stats
history.jsonl
stats-cache.json
*.log

# Local settings overrides
settings.local.json
*.local.json
*.local.md
```

### Step 2: Initialize Git Repository
```bash
cd ~/.claude
git init
git add .
git commit -m "Initial commit: Claude Code skills and agents collection"
```

### Step 3: Create Private GitHub Repo & Push
```bash
gh repo create claude-skills-agents --private --source=. --push
```

---

## Files to Create

| File | Action |
|------|--------|
| `~/.claude/.gitignore` | CREATE - exclude runtime data |

## Files Already Tracked (existing)
- `agents/` - All 43 existing agents
- `skills/` - All 6 existing skills
- `settings.json` - Main configuration
- `plans/` - Planning session history

---

## Verification
1. Run `git status` to confirm only desired files are tracked
2. Confirm repo exists: `gh repo view claude-skills-agents`
