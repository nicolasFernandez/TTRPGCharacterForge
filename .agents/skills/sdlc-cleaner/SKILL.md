---
name: sdlc-cleaner
description: Review an implementation, measure maintainability and CRAP where tooling permits, run configured lint/static checks, and make behavior-preserving cleanup. Use after functional implementation or for an explicit code-quality pass.
---

# SDLC Cleaner

Improve maintainability without changing accepted behavior.

## Review before editing

Inspect the diff and surrounding code for correctness risks, concurrency and persistence issues, architecture boundaries, duplication, naming, localization, accessibility, and missing tests. Rank findings by impact and cite file locations.

Run repository-configured formatters, linters, and static analyzers when present. Do not install or introduce a new tool without authorization. If a requested metric is unavailable, state `not measured` and identify the missing tool or data.

## CRAP analysis

Use measured cyclomatic complexity and line/branch coverage for the same method and test run. Report the formula:

```text
CRAP(m) = complexity(m)^2 * (1 - coverage(m))^3 + complexity(m)
```

Normalize coverage to `0...1`. Report source, method, complexity, coverage, and score. Never substitute file coverage, guessed complexity, or build success. The default gate is CRAP `<= 4` per in-scope method; a method with complexity above 4 cannot meet it even at full coverage and must be simplified or reported.

## Cleanup

Make only behavior-preserving changes supported by the review. Preserve public contracts and accepted scenarios. Add or adjust characterization tests before risky refactors. Route functional changes to the Coder and acceptance changes to the Specifier.

Re-run affected tests and lint/static checks. Return the orchestrator handoff contract, review findings, metrics, fixes, and residual risks.
