---
name: decision-brainstorm
description: Structured, unbiased option analysis before any significant or hard-to-reverse decision (architecture, library/tool choice, data model, infra, process, product scope). Use whenever there is more than one reasonable approach or the user asks "what should we use/do".
---

# Decision brainstorm

Purpose: avoid premature or majority-biased decisions. Surface real alternatives, compare them honestly,
recommend one, and let the **user** decide.

## Steps

1. **Frame**: one sentence for the decision, plus the forces: requirements, constraints, quality attributes
   (cost, latency, security, maintainability, team skill, lock-in), and how reversible the decision is.
2. **Generate 3–5 genuine options**, including:
   - the boring/established choice
   - the modern/recommended-by-upstream choice
   - the minimal "do nothing / simplest thing" option
   - one contrarian option if it's credible
3. **Gather evidence**, don't recall it. Check current docs, release dates, maintenance activity, benchmarks and
   real numbers (versions via nix/npm/PyPI/gh). Label anything unverified as an assumption.
4. **Compare** in a table. Use quantitative data where it exists.
5. **Steelman and doubt**: argue for the option you *don't* prefer. Name what would change your recommendation.
6. **Recommend**: pick one, give the 1–2 decisive reasons and the main risk. Then **ask** the user, using the question tool
   where available, with the recommended option first and marked "(Recommended)".
7. **Record** the chosen option for non-trivial decisions as an ADR (`docs/adr/NNNN-title.md`).

## Output template

```markdown
**Decision:** <one line>, reversible: <easy|costly|one-way>

| Option | Pros | Cons | Effort | Cost / perf (numbers) | Fits when |
|---|---|---|---|---|---|
| A (recommended) | … | … | S/M/L | … | … |
| B | … | … | … | … | … |
| C (simplest) | … | … | … | … | … |

**Recommendation:** A, because <decisive reasons>. Main risk: <…>; mitigated by <…>.
**Would switch to B if:** <condition>.
```

Keep it short: the table carries the detail, the prose carries the judgement. For trivial or easily reversible choices,
skip this skill, decide, and mention the decision in one line.
