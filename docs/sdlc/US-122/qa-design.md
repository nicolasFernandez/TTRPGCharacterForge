# US-122 bilingual SRD catalog validation QA design

## Document control

| Field | Value |
| --- | --- |
| User story | `US-122` |
| Accepted specification | `quality/features/issue-122-bilingual-srd-catalog-validation.feature` |
| Manual procedure | `quality/manual-tests/issue-122-bilingual-srd-catalog-validation.md` |
| Phase | QA design before implementation |
| Matrix | Supported: English/iPhone and Spanish/iPad |
| Execution status | Not run |
| Actual result | Not run |

This design does not treat automated extraction, AI comparison, source inspection, compilation, or test discovery as human SRD review evidence. The 178-entry provenance review remains a controlled human review. No test was executed while preparing this document.

## Automation boundary and traceability

| Accepted coverage | QA case | Disposition | Automated mapping | Actual result |
| --- | --- | --- | --- | --- |
| `AC-122-01` / `SC-122-01` | `QA-122-01` | Repository check: deterministic inventory, key uniqueness, and ledger reconciliation. Not a UI behavior. | `CAT-122-01` | Not run |
| `AC-122-02` / `SC-122-02` | `QA-122-02`, `QA-122-03` | Human review: every field and citation must be reviewed against the respective supplied PDF. Automation may check ledger completeness, but cannot award `verified` provenance. | `MAN-122-EN`, `MAN-122-ES`; ledger checker `CAT-122-02` | Not run |
| `AC-122-03` / `SC-122-03` | `QA-122-05` | Repository workflow/check: discrepancy records, accepted correction, focused test, and full validation. | `CAT-122-03` plus correction-specific unit test IDs | Not run |
| `AC-122-04` / `SC-122-04` | `QA-122-04` | Repository check plus human localized-source review. Stable pairing/non-localized fields and references are automatable; localized provenance is not. | `CAT-122-04`; `MAN-122-EN`, `MAN-122-ES` | Not run |
| `AC-122-05` / `SC-122-05` | `QA-122-05` | Human authorization gate. A test must not invent source precedence or translation policy. | `MAN-122-DISPOSITION` | Not run |
| `AC-122-06` / `SC-122-06` | `QA-122-05` | Unit/repository validation, not UI automation. Every accepted correction needs a focused test mapping. | `CAT-122-05` plus correction-specific unit test IDs | Not run |
| `AC-122-07` / `SC-122-07` | `QA-122-06` | User-visible offline behavior is the only XCUITest scope for this issue. | `UI-122-01`, `UI-122-02` | Not run |
| `AC-122-08` / `SC-122-08` | `QA-122-07` | Repository release-gate report derived from the reviewed ledger and executed validation artifacts. | `CAT-122-06` | Not run |

`CAT-*` names are stable check IDs for scripts or unit-test reports that the Coder may implement; they are not UI tests. `MAN-*` names identify required human evidence. The final ledger must keep reviewer-entered dispositions distinguishable from machine-derived findings.

## Proposed UI tests

Place later QA implementation in `TTRPGCharacterForgeUITests/US122CatalogOfflineUITests.swift`. The two tests use the same assertions with locale-specific expected data from an accepted smoke fixture.

| UI ID | XCTest intent | Traceability | Environment | Actual result |
| --- | --- | --- | --- | --- |
| `UI-122-01` | `testUI12201_correctedCatalogDataRemainsAvailableOfflineInEnglish()` | `AC-122-07`, `SC-122-07`, `QA-122-06` | `ENV-122-EN-PHONE` | Not run |
| `UI-122-02` | `testUI12202_correctedCatalogDataRemainsAvailableOfflineInSpanish()` | `AC-122-07`, `SC-122-07`, `QA-122-06` | `ENV-122-ES-PAD` | Not run |

The accepted smoke fixture must contain one corrected entry from every affected catalog section. If a section has no correction, it may contain one explicitly human-verified representative entry. The fixture is generated only from accepted ledger records and committed as a test fixture with the catalog revision, locale, section, entry ID, expected localized display strings, expected shared mechanics, and ledger record ID. QA must not infer expected strings from the app output or translate them itself.

Each test must:

1. Launch with the matching locale, clean ephemeral character state, accepted smoke fixture, deterministic offline denial, and direct start at the catalog smoke flow.
2. Assert the app reports the expected bundled catalog revision and locale.
3. For every fixture row, navigate to the named section/entry by stable identifier and assert the accepted localized name, description or visible rule summary, relevant choices/references, and shared rule values.
4. Exercise the entry in the rules-driven level-1 flow where the product currently exposes it (selection, granted choice, derived value, or spell availability), rather than asserting a debug-only data dump alone.
5. Assert every catalog lookup succeeded, no network request was attempted, and no fallback/placeholder value appeared.
6. Attach a screenshot for the fixture summary and each affected section. Screenshots supplement executed assertions; they are not pass evidence by themselves.

If an accepted correction is not exposed by the current level-1 UI, its correctness remains covered by its focused unit/repository test. Do not add production UI solely to surface a repository field for `US-122`.

## Supported device and locale matrix

Resolve available simulator model, runtime, and UDID at execution time. Use iOS/iPadOS 17; do not rely on a recorded UDID. Portrait is required on iPhone. Use the app's supported default orientation on iPad.

| Environment | Device class | Language arguments | Locale argument | Network | Required UI IDs | Actual result |
| --- | --- | --- | --- | --- | --- | --- |
| `ENV-122-EN-PHONE` | Available iPhone simulator, iOS 17 | `-AppleLanguages (en)` | `-AppleLocale en_US` | `deny-and-record` and disconnected simulator where controllable | `UI-122-01` | Not run |
| `ENV-122-ES-PAD` | Available iPad simulator, iPadOS 17 | `-AppleLanguages (es)` | `-AppleLocale es_ES` | `deny-and-record` and disconnected simulator where controllable | `UI-122-02` | Not run |

This split is the `supported` matrix defined by the QA role: all issue-specific behavior is covered across English/iPhone and Spanish/iPad. Repeating every case on both locales and both device classes is broad universal regression coverage owned by issue `#123`, not by `#122`. Any correction with device-class-specific presentation risk must be added to `#123`'s exhaustive matrix.

## Deterministic launch and reset contract

The Coder should provide bounded Debug/UI-test-only behavior before `CompositionRoot` resolves a catalog or store. Release launches must ignore or exclude these seams.

| Argument/environment | Value | Required behavior |
| --- | --- | --- |
| `-ui-testing` | flag | Enables only guarded UI-test seams. |
| `-ui-test-store` | `us122-<ui-id>-<locale>-<device>` | Uses an isolated file-backed SwiftData store. |
| `-ui-reset-store` | flag | Removes only the named `us122-` store before launch. It must never remove the normal store. |
| `-ui-fixture` | `us122-catalog-smoke` | Loads the committed, ledger-derived smoke manifest and seeds the minimal level-1 character state needed to exercise its entries. |
| `-ui-start-route` | `catalog-smoke` | Opens the testable level-1 catalog smoke route without depending on unrelated onboarding. It must still use production repositories and rule logic. |
| `-ui-network-mode` | `deny-and-record` | Rejects attempted network work immediately and exposes an attempted-request count. It must not replace bundled catalog loading with a test repository. |
| `-ui-expected-catalog-revision` | recorded commit/checksum ID | Fails visibly if the bundled catalogs do not match the smoke fixture's accepted revision. |
| Standard Apple args | `-AppleLanguages`, `-AppleLocale` | Select locale before repository construction; no in-test locale switching. |

Reset before every UI ID. Relaunch within a test only when needed to demonstrate that the same bundled data remains usable; omit `-ui-reset-store` on that relaunch. Fixture IDs and character UUIDs must be constant. Fixture generation is allowed only after the review ledger and corrections are accepted; generated expectations must be reviewed and committed, never silently regenerated during UI execution.

Suggested launch shape:

```swift
app.launchArguments = [
    "-ui-testing",
    "-ui-test-store", storeName,
    "-ui-reset-store",
    "-ui-fixture", "us122-catalog-smoke",
    "-ui-start-route", "catalog-smoke",
    "-ui-network-mode", "deny-and-record",
    "-ui-expected-catalog-revision", revision,
    "-AppleLanguages", "(en)",
    "-AppleLocale", "en_US"
]
```

## Offline control and observability

`deny-and-record` must be dependency injection at the app composition boundary. Any network attempt fails immediately and increments a counter exposed to UI testing. It cannot bypass or replace `BundledRulesRepository`; the smoke flow must load `rules_en.json` or `rules_es.json` from the application bundle. A value of zero is asserted after initial load and after each fixture entry is exercised.

At execution time, additionally use a documented simulator/host disconnection method when the environment offers one, and record it. If physical disconnection cannot be controlled deterministically, report it as `Not measured`; the rejecting dependency still provides app-level offline evidence. Source inspection or the existence of bundled JSON alone is not runtime offline evidence.

## Required accessibility and testability seams

Identifiers are stable and locale-independent. Visible values are asserted against the accepted locale-specific smoke fixture.

| Identifier | Required semantics |
| --- | --- |
| `catalog.smoke.screen` | Root of the bounded smoke journey; accessibility value includes locale and catalog revision. |
| `catalog.smoke.fixture-status` | `loaded` only when fixture revision and bundled revision match. |
| `catalog.smoke.section.<section-id>` | Entry point/container for `races`, `classes`, `backgrounds`, `skills`, `languages`, `equipment`, or `spells`. |
| `catalog.smoke.entry.<section-id>.<entry-id>` | Production UI element representing the accepted entry; entry ID, not localized name, is the selector. |
| `catalog.smoke.entry-name` | Visible localized name for the currently exercised entry. |
| `catalog.smoke.entry-description` | Visible localized description or rule summary where production UI exposes it. |
| `catalog.smoke.rule-value.<field-id>` | User-visible shared mechanic/value selected by stable field path. |
| `catalog.smoke.reference.<field-id>.<target-id>` | User-visible resolved choice/reference. |
| `catalog.smoke.exercise` | Performs the production level-1 action for the current fixture row. |
| `catalog.smoke.result` | Observable user-visible result of the production rule action. |
| `catalog.smoke.previous`, `catalog.smoke.next` | Deterministic fixture navigation. |
| `catalog.smoke.progress` | Exact `current/total` fixture progress, so omissions fail. |
| `catalog.smoke.error` | Visible catalog/fixture/load error; must be absent for a pass. |
| `catalog.test.network-request-count` | Debug/UI-test-only attempted network request count; must remain `0`. |

Where a stable production identifier already exists (for example `character.equipment.<id>` or `character.language.<id>`), prefer it rather than duplicating an identifier. Add bounded identifiers for race, class, background, skill, and spell rows/toggles that currently lack stable ID-based selectors. Tests must use semantic queries and bounded predicate waits (15 seconds for initial launch, 5 seconds for transitions), never coordinates, arbitrary sleeps, localized names as selectors, or list position.

## Repository-check design

The Coder should implement deterministic checks, preferably as test code plus a small review-ledger validator, that produce machine-readable output under a run-specific evidence directory:

- `CAT-122-01`: decode both catalogs; count all seven sections; reject blank or duplicate `(locale, section, entryID)` keys; reconcile exact inventory and ledger keys.
- `CAT-122-02`: require a disposition for every applicable reviewed field, a reason for `not-applicable`, source filename and page/named section, reviewer, and timestamp. It validates completeness, not truth of human verification.
- `CAT-122-03`: validate discrepancy schema and immutable before/after evidence; require accepted correction and focused validation linkage before resolution.
- `CAT-122-04`: compare locale key sets and compatible non-localized rule fields; validate every supported same-locale reference. Localized prose remains human-reviewed.
- `CAT-122-05`: execute both full catalogs through decode, schema/invariant, uniqueness, pairing, and cross-reference tests; map each accepted correction to an executed focused test result.
- `CAT-122-06`: calculate counts by locale/section and fail release readiness unless unreviewed and unresolved are zero and exact revisions/evidence paths are present.

No check may mutate review dispositions or mark an entry human-verified. A test bundle that compiles without executed test methods remains `Not run`/failed evidence.

## Evidence and artifact contract

Use a filesystem-safe timestamp such as `2026-10-07T143000`. Preserve exact commands and exit statuses.

| Artifact | Required path shape | Current result |
| --- | --- | --- |
| Review ledger | `quality/test-runs/<timestamp>-us122/review-ledger.json` | Not run |
| Inventory counts | `quality/test-runs/<timestamp>-us122/catalog-inventory.tsv` | Not run |
| Sorted key set | `quality/test-runs/<timestamp>-us122/catalog-entry-keys.tsv` | Not run |
| Discrepancy register | `quality/test-runs/<timestamp>-us122/discrepancies.json` | Not run |
| Catalog validation report | `quality/test-runs/<timestamp>-us122/catalog-validation.json` | Not run |
| Release-readiness report | `quality/test-runs/<timestamp>-us122/release-readiness.json` | Not run |
| Human review record | `quality/test-runs/<timestamp>-us122/manual-review.md` | Not run |
| English/iPhone UI run record | `quality/test-runs/<timestamp>-en-iphone-issue-122-catalog-offline.md` | Not run |
| Spanish/iPad UI run record | `quality/test-runs/<timestamp>-es-ipad-issue-122-catalog-offline.md` | Not run |
| English/iPhone result bundle | `/tmp/US-122-<timestamp>-en-iphone.xcresult` | Not run |
| Spanish/iPad result bundle | `/tmp/US-122-<timestamp>-es-ipad.xcresult` | Not run |

Each UI run record must include commit/build, exact catalog and PDF checksums, resolved device model/runtime/UDID, locale, network-control method, expanded command, start/end time, exit status, every UI ID's actual result, attachment names, and defects. Boot, build, install, launch, and test-method execution are separate statuses.

Execution command shape after runtime device discovery and `bootstatus -b`:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project TTRPGCharacterForge.xcodeproj \
  -scheme TTRPGCharacterForge \
  -destination 'platform=iOS Simulator,id=<RUNTIME-RESOLVED-UDID>' \
  -only-testing:TTRPGCharacterForgeUITests/US122CatalogOfflineUITests \
  -resultBundlePath '/tmp/US-122-<timestamp>-<environment>.xcresult'
```

## Ownership boundary with issue #123

`US-122` owns catalog correctness evidence, human provenance/review accounting, correction-specific focused checks, full catalog validation, and a supported offline smoke journey split across English/iPhone and Spanish/iPad.

Issue `#123` owns the broader regression system: exhaustive English and Spanish runs on both iPhone and iPad, end-to-end character journeys, persistence regression, both required PDF exports (`2014_EN_Character_Sheet.pdf` and `2014_ES_Character_Sheet.pdf`), circular transparent PNG export, layout/device regression, and recurring automation infrastructure. `US-122` may supply fixtures and tests that `#123` reuses, but it must not claim `#123`'s full release matrix.

## Risks and Coder handoff

- The UI-test target currently has only generated example/launch tests; `US122CatalogOfflineUITests.swift` does not exist.
- Stable selectors currently exist for equipment and languages, but the inspected race, class, background, skill, and spell choices need ID-based identifiers for this journey.
- The direct smoke route must exercise production catalog repositories and domain logic. A debug screen that merely echoes fixture JSON is insufficient.
- The smoke manifest cannot be finalized until human review accepts the ledger records and corrections. Until then UI implementation may build its harness, but its expected-data fixture is blocked.
- Source-precedence and translation-equivalence policy remains an open product decision. Conflicts remain unresolved and cannot enter the accepted smoke fixture.
- UI tests are not required for every one of the 178 ledger entries; deterministic key/ledger checks and human review cover completeness. UI tests sample every affected section to prove runtime bundled behavior.
- All actual results remain `Not run` until commands execute and test methods report results in `.xcresult` artifacts.

## QA design gate result

`completed`: every accepted scenario has an explicit manual, repository-check, or UI-test disposition; the UI matrix, deterministic state, launch arguments, offline control, accessibility seams, and evidence paths are defined. QA execution remains `Not run` and is gated on accepted review/correction data plus the bounded Coder seams above.
