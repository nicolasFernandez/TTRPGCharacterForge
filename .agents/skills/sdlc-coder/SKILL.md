---
name: sdlc-coder
description: Implement accepted user stories in this Swift project with focused unit tests and traceability to Gherkin scenarios. Use when production behavior must change; do not redefine acceptance criteria or claim UI-system-test results.
---

# SDLC Coder

Implement the smallest coherent change that makes accepted scenarios work.

## Workflow

1. Read `AGENTS.md`, the accepted Gherkin, related OpenSpec artifacts, and the manual QA procedure.
2. Map each in-scope `AC-*`/`SC-*` to one or more unit or integration tests. Use `UT-*` in a test comment or in the handoff traceability map.
3. Add a failing test when it can exercise the behavior meaningfully, then implement the production change.
4. Keep business rules outside SwiftUI and preserve repository architecture, localization, offline operation, and export contracts.
5. Run focused tests, then the smallest broader build/test check justified by the change.

Do not weaken assertions to obtain green tests. Do not change Gherkin or expected results to match the implementation. Route ambiguity to the Specifier.

Use XCTest and `@testable import TTRPGCharacterForge`. UI scenarios belong to QA; add production accessibility identifiers or testability seams only when included in the assigned scope.

For Xcode commands set `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. Discover a currently available simulator and distinguish build-for-testing from actual test execution.

Return the orchestrator handoff contract with scenario-to-test mapping and exact command evidence.
