# TTRPGCharacterForge agent guidance

## Product invariants

- Preserve the offline-first, bilingual, level-1 D&D 5e MVP unless the user explicitly changes scope.
- Target iOS and iPadOS 17 with SwiftUI and SwiftData. Keep domain and SRD rules independent of UI frameworks.
- Preserve the required exports: PDF plus a circular transparent PNG. The bundled sheet filenames are `2014_ES_Character_Sheet.pdf` and `2014_EN_Character_Sheet.pdf`.
- Optional AI portraits are a mobile contract behind a backend proxy. Do not add backend implementation or provider secrets to this repository without explicit authorization.
- Use `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` for Xcode and Simulator commands. Resolve available simulator identifiers at run time; never rely on a recorded UDID.

## SDLC orchestration

Use the `sdlc-orchestrator` skill when the user requests multi-agent SDLC execution or when one request materially spans two or more of these roles:

- `sdlc-specifier`: human documentation to acceptance Gherkin and manual QA procedures.
- `sdlc-coder`: unit tests and implementation that satisfy accepted scenarios.
- `sdlc-cleaner`: review, static analysis, CRAP analysis, linting, and behavior-preserving cleanup.
- `sdlc-hardener`: mutation testing and test-strength improvements.
- `sdlc-qa`: deterministic XCUITest automation and recorded system-test evidence.

Do not invoke the whole pipeline for a small, single-role task. The orchestrator owns routing, sequencing, file ownership, quality gates, and the final evidence summary. Role agents must follow their repository-local skill and return the handoff defined by the orchestrator.

## Evidence rules

- Never infer a passing test, QA result, coverage value, CRAP score, or mutation score from compilation or source inspection.
- Record exact commands, destinations, exit status, and artifact paths for executed checks.
- Keep `Expected result` as specification and `Actual result` as run evidence. Until executed, the actual result is `Not run`.
- Treat simulator boot, test-bundle compilation, test execution, and app launch as distinct states.
- Preserve unrelated worktree changes. Agents sharing a checkout must not edit the same files concurrently.
