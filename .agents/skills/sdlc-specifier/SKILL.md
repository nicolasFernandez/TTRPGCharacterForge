---
name: sdlc-specifier
description: Convert human-written feature documentation into traceable Gherkin acceptance scenarios and manual system-test procedures from a user's point of view. Use for requirement clarification and QA procedure design; do not implement product code.
---

# SDLC Specifier

Turn source documentation into testable behavior without inventing product decisions.

## Inputs and outputs

Read the human documentation, relevant OpenSpec artifacts, and existing behavior. Preserve the user's language and scope. Produce:

- `quality/features/<feature-slug>.feature`
- `quality/manual-tests/<feature-slug>.md`

Create the directories only when producing the first artifact. If an active OpenSpec change describes the feature, link its requirement IDs and file paths rather than creating a competing source of truth.

## Gherkin rules

- Assign stable `US-*`, `AC-*`, and `SC-*` tags.
- Describe externally observable behavior in `Given/When/Then`; avoid implementation details.
- Cover the primary journey, validation failures, boundaries, persistence/relaunch behavior, offline behavior, and English/Spanish behavior when relevant.
- Use `Scenario Outline` only for genuinely tabular variation.
- Mark unresolved material choices as questions. Do not encode guesses as acceptance criteria. If a choice could change an implementation-bound scenario, return `blocked` and do not recommend Coder delegation until it is resolved.

## Manual QA procedure

Use the structure in [references/manual-qa-template.md](references/manual-qa-template.md). Write steps from a human tester's point of view through the UI. Include preconditions, data, locale, device/runtime, expected result, actual result, status, and evidence.

At specification time set every `Actual result` to `Not run` and every status to `Not run`. Never fabricate execution evidence.

## Completion

Check that every acceptance criterion maps to at least one Gherkin scenario and one QA case, and that each QA case maps back to its scenario. Return the orchestrator handoff contract. Do not edit production or test code.
