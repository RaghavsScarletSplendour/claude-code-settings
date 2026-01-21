---
name: china-product-researcher
description: Research products from Chinese manufacturing platforms (Made-in-China, Alibaba, 1688) using Claude for Chrome. Use when user requests supplier research, product sourcing from China, or asks to find manufacturers for specific products. Triggers on phrases like "find me [product] from China", "source [product]", "research suppliers for [product]", or "contact manufacturers".
agent: china-product-orchestrator
---

# China Product Researcher

Research Chinese manufacturing platforms to find suppliers, compare products, contact manufacturers, and document findings.

**Target Platform:** Claude for Chrome (browser automation required)

## Before Starting

1. Read `references/company-info.md` to load company context and message templates
2. Confirm the product and its intended application with the user
3. Identify which platform to search (default: Made-in-China)

## Research Workflow

### Step 1: Navigate to Platform

1. Open browser and navigate to the target platform:
   - **Made-in-China:** `https://www.made-in-china.com`
   - **Alibaba:** `https://www.alibaba.com`
   - **1688 (Chinese):** `https://www.1688.com`
2. Use the search bar to search for the product
3. **Critical:** Stay on the platform. Do not click external links or ads that navigate away

### Step 2: Evaluate Search Results

For each promising result, collect:
- Product name and specifications
- Company/manufacturer name
- Price (if displayed)
- MOQ (minimum order quantity)
- Product URL

**Selection criteria:**
- Verified/Gold suppliers preferred
- Check transaction history and reviews if available
- Look for suppliers with relevant certifications
- Prioritize suppliers with clear pricing and specs

### Step 3: Contact Manufacturers (with deduplication)

**CRITICAL:** Before contacting any supplier, check the deduplication registry.

For selected suppliers:
1. **Slugify** the company name (lowercase, hyphens)
2. **Check** `contacted_companies.txt` - skip if already listed
3. If not in registry:
   - Click "Contact Supplier" or equivalent button
   - Use the inquiry template from `references/company-info.md`
   - Customize the message with product name and application
   - Send the inquiry
   - **Immediately append** the company slug to `contacted_companies.txt`

**Volume control:** Respect the max contacts limit (default: 10 total across all products).

### Step 4: Document Research

Create a research document with this structure:
```markdown
# [Product Name] Supplier Research

**Date:** [YYYY-MM-DD]
**Researched for:** JD Jones & Co (P) Ltd
**Application:** [What the product will be used for]
**Platform:** [Made-in-China / Alibaba / 1688]

## Suppliers Found

### 1. [Company Name]
- **Product:** [Product name/model]
- **Price:** [Price or "Contact for price"]
- **MOQ:** [Quantity]
- **URL:** [Full product URL]
- **Contacted:** Yes
- **Notes:** [Any relevant observations]

### 2. [Company Name]
- **Product:** [Product name/model]
- **Price:** [Price or "Contact for price"]
- **MOQ:** [Quantity]
- **URL:** [Full product URL]
- **Contacted:** Already (via PTFE sheets)
- **Notes:** [This supplier was already contacted for another product]

## Summary
[Brief summary of findings, recommendations, or next steps]
```

Save as `[product-name]-research.md` in the current working directory.

## Safety Rules

- **Never navigate away** from the sourcing platform to external sites
- **Never enter payment information** or complete transactions
- **Never share sensitive company data** beyond what's in the inquiry template
- If CAPTCHA or login is required, inform the user

## Output Directory Structure

After completion, the working directory will contain:
```
./
├── ptfe-sheets-research.md          ← Research report for product 1
├── hydraulic-seals-research.md      ← Research report for product 2
├── industrial-gaskets-research.md   ← Research report for product 3
└── contacted_companies.txt          ← Deduplication registry
```

The registry file contains one company slug per line to prevent duplicate outreach.

## Example Usage

**User:** Find me PTFE gasket sheets for our gland packing production

**Workflow:**
1. Read company-info.md
2. Navigate to made-in-china.com
3. Search "PTFE gasket sheet"
4. Evaluate top 5-10 results
5. Check `contacted_companies.txt` before each contact
6. Contact up to limit suppliers (skip duplicates)
7. Append new contacts to `contacted_companies.txt`
8. Create `ptfe-gasket-sheets-research.md` with findings

## References

- `references/company-info.md` — Company profile and inquiry template (read this first)
- `contacted_companies.txt` — Deduplication registry tracking all contacted companies
