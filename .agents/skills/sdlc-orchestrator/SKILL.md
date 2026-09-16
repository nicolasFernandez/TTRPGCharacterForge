---
name: sdlc-orchestrator
description: Route a software-delivery request among the repository's specifier, coder, cleaner, hardener, and QA roles; coordinate handoffs, ownership, quality gates, and rework. Use for explicitly requested multi-agent SDLC work or work that materially spans multiple roles.
---

# SDLC Orchestrator

Coordinate the work; do not impersonate every role inside one undifferentiated pass.

Read [references/handoff-contract.md](references/handoff-contract.md) before delegating. Inspect `AGENTS.md`, the current worktree, and relevant OpenSpec artifacts first. Preserve user scope and repository product invariants.

## Route the request

Select only the roles needed for the outcome:

| Need | Role skill | Owns |
| --- | --- | --- |
| Clarify human requirements | `sdlc-specifier` | Gherkin, traceability, manual QA procedure |
| Implement accepted behavior | `sdlc-coder` | Unit tests and production code |
| Review and simplify safely | `sdlc-cleaner` | Review findings, metrics, lint fixes, refactors |
| Challenge test effectiveness | `sdlc-hardener` | Mutation run, surviving-mutant analysis, test-only hardening |
| Automate and execute user journeys | `sdlc-qa` | XCUITests, run records, UI evidence |

For a full feature, prefer this dependency graph:

```text
Specifier -> QA design -> Coder -> Cleaner -> Hardener -> QA execution
```

QA designs automation after acceptance artifacts stabilize and hands required accessibility identifiers, fixtures, launch arguments, offline controls, and the device/locale matrix to the Coder. Run QA implementation concurrently with coding only when file ownership is disjoint and those seams are already stable. Run mutation testing after cleanup because cleanup changes the code under test.

## Delegate bounded tasks

Create a fresh subagent per role with:

- the exact role skill path to read;
- the user outcome and in-scope requirement or scenario IDs;
- allowed files and explicit non-goals;
- required inputs and known worktree changes;
- the required verification and handoff fields.

Use distinct task names such as `specifier_<slug>` and `coder_<slug>`. Parallelize read-only analysis or disjoint files when useful. In a shared checkout, assign one writer per file and never let agents edit the Xcode project concurrently.

Before delegation, create a working manifest in the orchestration handoff or task messages with `path`, `owner`, `allowed editors`, `phase`, and whether the path was dirty before orchestration. Ownership transfers between sequential phases; it never implies permission to discard pre-existing edits.

Set each quality gate to `required`, `best-effort`, or `skipped with reason` at kickoff. Track lint, CRAP, mutation, iPhone QA, iPad QA, English QA, and Spanish QA separately. For an explicitly requested full pipeline, CRAP and mutation are required. For “fully test” on this universal bilingual app, default to English and Spanish on both an iPhone and an iPad unless the user narrows the matrix.

## Enforce gates

Advance only when the prior role returns usable evidence:

1. Specification gate: each acceptance criterion has stable IDs, Gherkin, and a manual QA procedure. A material unresolved choice that could change an implementation-bound scenario blocks Coder delegation.
2. QA design gate: each UI scenario has a proposed `UI-*` mapping, environment matrix, deterministic state plan, and list of required app testability seams.
3. Implementation gate: mapped unit tests and production behavior pass targeted checks.
4. Cleanup gate: blocking review findings are resolved; lint and CRAP results are measured, or a best-effort gate is clearly marked unavailable. Unavailable required tooling blocks advancement.
5. Hardening gate: the mutation command completed and in-scope survivors are killed or documented with a defensible disposition. The default target is CRAP `<= 4` per measured method and 100% mutation score for eligible in-scope business logic; report exclusions and tool limitations.
6. QA gate: deterministic UI tests ran on the selected device/locale matrix, with actual results and evidence paths recorded.

Do not convert an unavailable tool into a passing gate. A required unavailable tool is `blocked`; a best-effort unavailable tool is `not measured`. Keep mutation score and CRAP as separate results.

## Rework and completion

Route requirement ambiguity to the Specifier, functional defects to the Coder, maintainability failures to the Cleaner, surviving non-equivalent mutants to the Hardener, and UI automation instability to QA. Limit automatic role loops to three passes; then report the repeated blocker with evidence and request direction.

Finish with a compact traceability summary from requirement ID through tests and results. Identify skipped roles and why. A role report is evidence only for commands that actually ran.
