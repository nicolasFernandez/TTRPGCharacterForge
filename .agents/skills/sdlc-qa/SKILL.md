---
name: sdlc-qa
description: Convert approved manual QA procedures into deterministic XCUITest system tests and execute them with device-specific evidence. Use for UI automation and user-journey verification; keep expected and actual results separate.
---

# SDLC QA

Automate the approved human procedure while preserving its user-visible intent.

## Build deterministic UI tests

- Before coding begins, return a QA design handoff with the `UI-*` plan, required accessibility identifiers, fixture/reset and launch-argument contract, offline-control method, and device/locale matrix. This design handoff may be `completed` without running tests.
- Map each `QA-*`/`SC-*` to a `UI-*` identifier in comments or the handoff map.
- Start from a known state using launch arguments, launch environment, seeded fixtures, or an explicit reset flow.
- Use stable accessibility identifiers and semantic queries. Do not use screen coordinates or arbitrary sleeps.
- Wait on observable predicates with bounded timeouts and useful failure messages.
- Keep locale, device class, orientation, network state, clock/data dependencies, and permissions explicit.
- Assert user-visible outcomes, persistence after relaunch, offline behavior, and English/Spanish behavior where the procedure requires them.

Use one of these explicit matrices unless the accepted procedure defines another:

- smoke: one current iPhone simulator and one locale;
- supported: all behavioral cases split across English/iPhone and Spanish/iPad;
- exhaustive: all behavioral cases in English and Spanish on both an iPhone and an iPad.

Interpret “fully test” as exhaustive for this universal bilingual app unless the user narrows it. For offline scenarios, use a seeded local SwiftData store plus a documented disconnected simulator or deterministic no-network configuration; source inspection alone is not offline execution evidence.

Prefer changes inside `TTRPGCharacterForgeUITests/`. If production code needs accessibility identifiers or a testability seam, request a bounded Coder change unless that file was explicitly assigned to QA.

## Execute and record

Set `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. Discover and boot an available simulator, wait for `simctl bootstatus -b`, then run the targeted UI tests. Retry only when evidence indicates infrastructure or simulator failure, and record every attempt.

Update a run-specific copy under `quality/test-runs/<timestamp>-<locale>-<device-class>-<feature-slug>.md`; do not overwrite the canonical manual procedure's expectations. Use an ISO-like filesystem-safe timestamp such as `2026-09-16T143000`. Record device model, runtime, locale, app build/commit, exact command, timestamps, actual result for every step/case, status, `.xcresult` path, screenshots/attachments, and defect IDs.

Compilation, installation, launch, and execution are separate evidence. Never mark a QA case passed unless its assertions executed successfully.

Return the orchestrator handoff contract with traceability and evidence paths.
