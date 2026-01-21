# Plan: Add Deduplication & Volume Control to China Product Research

## Problem Statement

With parallel workers researching multiple products:
1. **Volume explosion**: 3 products × 5 contacts = 15 companies messaged (overwhelming)
2. **Duplicate contacts**: Company X sells both "PTFE sheets" AND "hydraulic seals" → two workers might contact the same company

## Solution: Centralized Registry + Per-Product Files

### New File Structure

```
./
├── ptfe-sheets-research.md         ← One file per PRODUCT (contains all companies)
├── hydraulic-seals-research.md
├── industrial-gaskets-research.md
└── contacted_companies.txt         ← DEDUPLICATION REGISTRY (simple list)
```

**Key change:** No more `companies_messaged/` folder with one file per company. Instead:
- Each product gets ONE research file containing all suppliers found/contacted
- A simple text file tracks which companies have been messaged (across all products)

### Architecture

```
┌─────────────────────────────┐
│  china-product-orchestrator │
│  - Sets GLOBAL contact limit│
│  - Creates registry file    │
└─────────────────────────────┘
           │
    ┌──────┼──────┐
    ▼      ▼      ▼
┌──────┐┌──────┐┌──────┐
│Worker││Worker││Worker│
│Prod A││Prod B││Prod C│
└──────┘└──────┘└──────┘
    │      │      │
    └──────┼──────┘
           ▼
   contacted_companies.txt    ← Workers READ before contact, APPEND after
```

### Key Changes

#### 1. Worker: Pre-Contact Check with Registry
Before contacting any company, worker MUST:
```
1. Slugify company name → "shanghai-ptfe-materials-co"
2. Read contacted_companies.txt
3. If company slug IS IN the file:
   - DO NOT send message
   - Note in research report: "Already contacted for another product"
4. If company slug NOT IN the file:
   - Proceed with contact
   - IMMEDIATELY append slug to contacted_companies.txt
   - Log in research report with "Contacted: Yes"
```

#### 2. Registry File Format
`contacted_companies.txt` — simple, one slug per line:
```
shanghai-ptfe-materials-co
guangzhou-sealing-tech
ningbo-industrial-supplies
```

#### 3. Orchestrator: Volume Control
```
GLOBAL_LIMIT = 10 contacts total (configurable)
per_worker_limit = ceil(10 / num_products)

Example: 3 products, limit 10
→ Each worker contacts max 4 suppliers
```

Orchestrator ensures registry file exists before spawning workers.

---

## Implementation Steps

### Step 1: Update `china-product-worker.md`

**A. Remove `companies_messaged/` folder logic entirely**

**B. Add registry-based deduplication to Step 3:**

```markdown
### Step 3: Contact Manufacturers (with deduplication)

**CRITICAL: Before contacting ANY supplier:**
1. Slugify company name (lowercase, hyphens, e.g., "Shanghai PTFE Co" → "shanghai-ptfe-co")
2. Read `[working_directory]/contacted_companies.txt`
3. If slug IS IN the file:
   - DO NOT send message
   - In research report, mark: "Contacted: Already (via another product)"
4. If slug NOT IN the file:
   - Proceed with contact
   - IMMEDIATELY append slug to contacted_companies.txt (one line)
   - In research report, mark: "Contacted: Yes"

**Contact limit:** Respect the `max_contacts` parameter from orchestrator.
```

**C. Update research report format** - all suppliers for a product go in ONE file:
```markdown
# [Product Name] Supplier Research

## Suppliers Found

### 1. Shanghai PTFE Co
- **Contacted:** Yes
- **Price:** $X/kg
- ...

### 2. Guangzhou Sealing
- **Contacted:** Already (via PTFE sheets)
- ...
```

### Step 2: Update `china-product-orchestrator.md`

**A. Remove `companies_messaged/` directory creation**

**B. Add registry file initialization:**
```bash
touch ./contacted_companies.txt  # Create if doesn't exist
```

**C. Add volume control to worker prompts:**
```
**Max Contacts:** [per_worker_limit] (global limit: 10)
**Registry File:** [working_dir]/contacted_companies.txt
```

### Step 3: Clean up old structure

Remove `companies_messaged/.gitkeep` from skill folder (no longer used).

---

## Files to Modify

| File | Changes |
|------|---------|
| `~/.claude/agents/china-product-worker.md` | Remove companies_messaged/ logic, add registry check, update report format |
| `~/.claude/agents/china-product-orchestrator.md` | Create registry file, add volume limits, remove mkdir companies_messaged |
| `~/.claude/skills/china-product-researcher/SKILL.md` | Remove companies_messaged/ references |
| `~/.claude/skills/china-product-researcher/companies_messaged/.gitkeep` | Delete |

---

## Configuration

- **Default global limit**: 10 contacts total
- User can override via prompt: "Research X, Y, Z (max 5 contacts)"

---

## Verification

1. Research 3 related products (e.g., "PTFE sheets", "PTFE gaskets", "PTFE rope")
2. Check `contacted_companies.txt` - each company slug appears ONLY ONCE
3. Verify total lines in registry ≤ 10 (global limit)
4. In research reports, duplicates should show "Contacted: Already (via [product])"
5. Confirm output structure:
   ```
   ./
   ├── ptfe-sheets-research.md
   ├── ptfe-gaskets-research.md
   ├── ptfe-rope-research.md
   └── contacted_companies.txt
   ```
