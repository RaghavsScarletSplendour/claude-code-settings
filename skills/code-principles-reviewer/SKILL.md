---
name: code-principles-reviewer
description: Review entire codebases against clean code principles (KISS, YAGNI, DRY, SOLID, Boy Scout Rule, Composition Over Inheritance, POLA). Use when reviewing AI-generated code or code from junior developers. Triggers on "review code principles", "check clean code", "review for SOLID", "check DRY violations", "code quality review", or requests to audit code against software engineering best practices. Supports two modes via flags in the request, "strict" for AI code and "mentoring" for educational feedback.
---

# Code Principles Reviewer

Senior Software Architect and Code Auditor specializing in Clean Code, SOLID principles, and architectural integrity. Reviews code for technical debt, code smells, and violations of best practices.

## Workflow

### 1. Gather Code to Review

**For full codebase review:**
- Use `find` and `view` to explore the repository structure
- Focus on source directories (src/, lib/, app/, etc.)
- Skip generated files, node_modules, vendor/, build/, dist/

**For recent git changes:**
```bash
# Recent commits (last 7 days)
git log --since="7 days ago" --oneline --name-only

# Uncommitted changes
git diff --name-only

# Specific commit range
git diff --name-only HEAD~5..HEAD
```

### 2. Review Against Principles Checklist

Evaluate code strictly against these principles:

#### Logic Principles
| Principle | Check For |
|-----------|-----------|
| **DRY** (Don't Repeat Yourself) | Duplicated code blocks, copy-pasted logic, repeated patterns that should be abstracted |
| **KISS** (Keep It Simple, Stupid) | Over-engineered solutions, unnecessary complexity, convoluted control flow |
| **YAGNI** (You Ain't Gonna Need It) | Speculative features, unused abstractions, premature optimization |
| **Fail Fast** | Silent failures, swallowed exceptions, delayed error detection |

#### SOLID Architecture
| Principle | Check For |
|-----------|-----------|
| **Single Responsibility (SRP)** | Classes/functions doing multiple unrelated things |
| **Open/Closed (OCP)** | Code requiring modification instead of extension for new features |
| **Liskov Substitution (LSP)** | Subtypes that can't substitute base types without breaking behavior |
| **Interface Segregation (ISP)** | Fat interfaces forcing unused method implementations |
| **Dependency Inversion (DIP)** | High-level modules depending on concrete implementations |

#### Readability
| Principle | Check For |
|-----------|-----------|
| **Meaningful Naming** | Cryptic names, single letters, misleading identifiers |
| **Small Functions** | Functions > 20-30 lines, deeply nested logic |
| **Self-Documenting Code** | Code requiring comments to explain *what* it does |
| **Avoid Magic Numbers** | Hardcoded values without named constants |

#### Design
| Principle | Check For |
|-----------|-----------|
| **Composition over Inheritance** | Deep inheritance hierarchies, inheritance for code reuse |
| **Encapsulation** | Exposed internals, public fields, leaky abstractions |
| **Principle of Least Astonishment (POLA)** | Surprising side effects, unexpected behavior |

### 3. Output Format

Structure the review exactly as follows:

```markdown
## Executive Summary
[2-sentence overview of code quality and most critical concern]

## Principle Violations

### 1. [Descriptive Title]
- **The Issue:** [What is wrong - specific code reference]
- **The Principle:** [Which rule is being broken]
- **The Impact:** [Why this matters for maintainability/scalability]
- **Suggestion:** [Concrete fix or refactor approach]

### 2. [Next violation...]
[Continue for all violations found]

## Metrics Summary
| Category | Violations |
|----------|------------|
| Logic (DRY/KISS/YAGNI/Fail Fast) | X |
| SOLID | X |
| Readability | X |
| Design | X |
| **Total** | **X** |
```

### 4. Severity Guidelines

Rate each violation:
- **Critical:** Bugs waiting to happen, security risks, data corruption potential
- **Major:** Significant maintainability impact, scaling blockers
- **Minor:** Style issues, minor readability concerns

Focus reporting on Critical and Major issues. Mention Minor issues only if few other violations exist.

