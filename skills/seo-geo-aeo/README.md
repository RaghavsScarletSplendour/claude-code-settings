# SEO / GEO / AEO Audit — Skill for Claude

Automatically audits any website across three dimensions of modern search visibility:

- **SEO** — Traditional search engine optimization (Google, Bing): title tags, meta descriptions, heading structure, schema markup, internal links, content quality
- **GEO** — Generative Engine Optimization for AI-powered search (Perplexity, ChatGPT Search, Google AI Overviews, Gemini): E-E-A-T signals, entity clarity, factual density, author authority
- **AEO** — Answer Engine Optimization for featured snippets and voice search: FAQ schema, HowTo schema, question-phrased headings, direct answer formatting

---

## How to use

Once installed, just give Claude a URL and ask about search performance:

> "Can you audit burningstickcreative.com for SEO?"
> "Check my site example.com — why isn't it ranking?"
> "Audit this URL for AI search readiness: example.com"
> "Run a full SEO, GEO, and AEO audit on my website"

Claude will ask whether you want a **Quick Audit** (top issues and scores) or a **Full Audit** (comprehensive breakdown), then crawl the site across multiple pages before delivering a structured report with a downloadable Word doc and PDF.

---

## Installation

**Installed locally for Claude Code** at `~/.claude/skills/seo-geo-aeo/`. It loads automatically — just ask Claude to audit a site (see *How to use* above).

This copy has been adapted from the original Cowork/cloud-sandbox version to run on a local machine:
- Reports are written to the current working directory (not a cloud `/sessions/.../mnt/outputs/` path).
- `docx` is installed locally on demand; no global install needed.
- PDF export uses LibreOffice if present, and gracefully skips (delivering the `.docx` only) if not. To enable PDF: `brew install --cask libreoffice`.

For the original ZIP-upload install in **Claude's Cowork / desktop app**: download the repo ZIP (**Code → Download ZIP** on GitHub), then in the Claude app go to Customize → **Skills** → **+** and upload it.

---

## Repository structure

```
SEO-GEO-AEO-Skill/
├── SKILL.md             ← Audit instructions (source of truth)
└── README.md
```

---

## Version history

**1.0.0** — Initial release
- Quick and Full audit modes
- Multi-page site crawl (up to 15 pages for Quick, unlimited for Full)
- SEO, GEO, and AEO scoring with priority recommendations matrix
- Downloadable audit report as both Word (.docx) and PDF
