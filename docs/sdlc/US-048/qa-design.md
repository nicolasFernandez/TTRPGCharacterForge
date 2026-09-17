# US-048 Currency converter UI automation design

## Document control

| Field | Value |
| --- | --- |
| User story | `US-048` |
| Accepted specification | `docs/sdlc/US-048/US-048.feature` |
| Manual procedure | `docs/sdlc/US-048/manual-qa.md` |
| Phase | QA design before implementation |
| Execution status | Not run |
| Actual result | Not run |

This design preserves the user-visible intent of the accepted scenarios. It does not record build, launch, or UI-test evidence; those remain `Not run` until QA execution produces an `.xcresult` and a run-specific record under `quality/test-runs/`.

## Repository baseline

- The UI-test target exists, but currently contains only the generated launch/example tests. There is no deterministic fixture, reset, locale, or offline seam.
- `CompositionRoot` creates the persistent SwiftData container directly. The app has no launch-argument handling and no UI-test-specific data-store location.
- Characters are opened from `CharactersListView` into the existing character editor sheet. The currency entry point and converter UI do not exist yet.
- No stable accessibility identifiers are present on the character list/editor path inspected for this feature.

QA implementation should be contained in a new `TTRPGCharacterForgeUITests/US048CurrencyConverterUITests.swift` plus test-only helpers inside the UI-test target. Production identifiers and deterministic launch seams listed below are bounded requests for the Coder. QA must not edit production files without a later ownership transfer.

## Traceability and proposed UI tests

| UI ID | XCTest intent | Acceptance criteria | Gherkin scenarios | Manual QA cases | Environments | Actual result |
| --- | --- | --- | --- | --- | --- | --- |
| `UI-001` | `testUI001_opensFiveDenominationConverter()` | `AC-001` | `SC-001` | `QA-001` | `ENV-001`...`ENV-004` | Not run |
| `UI-002` | `testUI002_normalizesMixedBalanceExactly()` | `AC-002`, `AC-003` | `SC-001` | `QA-002` | `ENV-001` | Not run |
| `UI-003` | `testUI003_convertsEveryDenominationBidirectionally()` | `AC-002`, `AC-003` | `SC-002` | `QA-003` | `ENV-001` | Not run |
| `UI-004` | `testUI004_persistsBalanceWithoutChangingEquipment()` | `AC-004` | `SC-003` | `QA-004` | `ENV-001` | Not run |
| `UI-005` | `testUI005_migratesLegacyWealthWithoutChangingEquipment()` | `AC-004` | `SC-004` | `QA-005` | `ENV-001`...`ENV-004` | Not run |
| `UI-006` | `testUI006_formatsExactGPReferenceForLocale()` | `AC-005` | `SC-005` | `QA-006` | `ENV-001`, `ENV-002` | Not run |
| `UI-007` | `testUI007_rejectsInvalidInputsAtomically()` | `AC-006` | `SC-006` | `QA-007` | `ENV-001`, `ENV-002` | Not run |
| `UI-008` | `testUI008_rejectsOverflowAtomically()` | `AC-006` | `SC-007` | `QA-008` | `ENV-001` | Not run |
| `UI-009` | `testUI009_convertsPersistsAndRemainsUsableOffline()` | `AC-007`, `AC-008` | `SC-008`, `SC-009` | `QA-009` | `ENV-001`...`ENV-004` | Not run |

`UI-003` and `UI-007` should use XCTest subactivities for every example row so a single row failure identifies its denomination/value. Each row must relaunch from a freshly reset fixture; one row must not inherit persistence from another.

## Required exhaustive environment matrix

Run in portrait orientation using the exact models and runtime below. The execution agent must resolve the simulator UDID at run time and record it; a remembered UDID is not part of this contract.

| Environment | Device | Runtime | Language argument | Locale argument | Network mode | Required UI IDs | Actual result |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `ENV-001` | iPhone 15 | iOS 17.5 | `-AppleLanguages (en)` | `-AppleLocale en_US` | deny and record | `UI-001`...`UI-009` | Not run |
| `ENV-002` | iPhone 15 | iOS 17.5 | `-AppleLanguages (es)` | `-AppleLocale es_ES` | deny and record | `UI-001`, `UI-005`, `UI-006`, `UI-007`, `UI-009` | Not run |
| `ENV-003` | iPad Pro (11-inch) (4th generation) | iPadOS 17.5 | `-AppleLanguages (en)` | `-AppleLocale en_US` | deny and record | `UI-001`, `UI-005`, `UI-009` | Not run |
| `ENV-004` | iPad Pro (11-inch) (4th generation) | iPadOS 17.5 | `-AppleLanguages (es)` | `-AppleLocale es_ES` | deny and record | `UI-001`, `UI-005`, `UI-009` | Not run |

Before execution, verify that these simulator profiles are installed with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl list devices available`. If the required 17.5 runtime/model is unavailable, the corresponding required gate is blocked; do not silently substitute a newer OS or another device. Simulator discovery was attempted during design but CoreSimulatorService was unavailable in the sandbox, so availability is not established by this document.

## Deterministic launch and state contract

### Launch arguments

The app should accept these Debug/UI-test-only arguments through a small launch configuration parsed before `CompositionRoot` creates its `ModelContainer`:

| Argument | Values | Required behavior |
| --- | --- | --- |
| `-ui-testing` | flag | Enables only the bounded test seams below. Must not change Release behavior. |
| `-ui-test-store` | `us048-<test>-<locale>-<device>` | Uses a file-backed SwiftData store in a UI-test-specific Application Support subdirectory. The name makes tests independent while allowing same-test relaunch persistence. |
| `-ui-reset-store` | flag | Deletes only the named UI-test store, then seeds the selected fixture. Use on the first launch of a case only. |
| `-ui-fixture` | fixture name below | Seeds exactly one character when the named test store is empty. It must be idempotent. |
| `-ui-network-mode` | `deny-and-record` | Routes every app network request through a rejecting spy and maintains a request count. The currency flow must remain usable with count `0`. |
| `-ui-start-route` | `currency` | Opens the seeded character's converter deterministically after launch. This avoids coupling currency tests to unrelated editor navigation; `UI-001` additionally exercises the real character-list entry point without this argument. |

Locale remains controlled by Apple's standard `-AppleLanguages` and `-AppleLocale` launch arguments. Do not switch locale inside the test or rely on the simulator's prior Settings state.

Suggested XCTest construction for the initial launch is:

```swift
app.launchArguments = [
    "-ui-testing",
    "-ui-test-store", storeName,
    "-ui-reset-store",
    "-ui-fixture", fixture,
    "-ui-network-mode", "deny-and-record",
    "-AppleLanguages", "(en)",
    "-AppleLocale", "en_US"
]
```

For a persistence relaunch, terminate the app and launch it again with the same store name, locale, and network mode while omitting `-ui-reset-store` and `-ui-fixture`. This distinguishes process relaunch from a new fixture and proves file-backed persistence.

### Fixtures

All fixture IDs and character UUIDs must be constant. Each fixture records equipment `Leather Armor` and `Dagger`; the tests compare those visible items before and after save/relaunch.

| Fixture | Character state |
| --- | --- |
| `us048-zero` | `Currency QA`; persisted balance `0 pp, 0 gp, 0 ep, 0 sp, 0 cp`; known equipment. |
| `us048-existing` | `Currency QA`; persisted balance `1 pp, 2 gp, 0 ep, 3 sp, 4 cp`; known equipment. |
| `us048-five-gp` | `Currency QA`; persisted balance `0 pp, 5 gp, 0 ep, 0 sp, 0 cp`; known equipment. |
| `us048-legacy-37-gp` | `Currency QA Legacy`; legacy `startingWealthGP = 37`; no five-denomination balance; known equipment. |

The reset implementation must validate that `-ui-testing` is also present, validate the store name against a strict `us048-` prefix, and remove only that test store. It must never delete the normal app store. Tests should generate a distinct store name per UI ID, locale, and device class and remove it after the case using the same guarded seam.

### Offline observability

`deny-and-record` must be deterministic dependency injection, not a claim inferred from source inspection. It should reject any attempted request immediately and expose the count through a Debug/UI-test-only accessibility element `currency.test.network-request-count`. `UI-009` asserts its value remains `0` after opening, applying, terminating, and relaunching. A nonzero count fails the test even if the currency UI otherwise works. This verifies the app-level contract; the manual execution should additionally run the simulator disconnected when the environment provides a controlled way to do so.

## Required accessibility contract

Identifiers are locale-independent. Visible labels/values remain localized and are asserted separately.

| Identifier | Element/semantic value |
| --- | --- |
| `characters.list` | Saved-character list container. |
| `character.row.currency-qa` | Fixture character row. |
| `character.currency.open` | Currency entry action on the selected character. |
| `currency.converter.screen` | Converter root, with character name in its value or child label. |
| `currency.converter.title` | Localized title. |
| `currency.input.cp` | cp text field; accessibility value is the unformatted whole-number input. |
| `currency.input.sp` | sp text field. |
| `currency.input.ep` | ep text field. |
| `currency.input.gp` | gp text field. |
| `currency.input.pp` | pp text field. |
| `currency.label.cp`...`currency.label.pp` | Localized full denomination labels; abbreviations may remain SRD abbreviations. |
| `currency.total-gp` | Localized exact gp reference, for example `11.61 gp` / `11,61 gp`. |
| `currency.total-cp` | User-visible exact copper total used by `UI-002`/`UI-003`. |
| `currency.apply` | Localized apply-to-character action. |
| `currency.validation.message` | Localized validation or overflow message; absent when valid. |
| `currency.save.status` | Observable saved confirmation/status after a successful apply. |
| `character.equipment.summary` | Equipment section/container. |
| `character.equipment.leather-armor` | Visible seeded equipment item. |
| `character.equipment.dagger` | Visible seeded equipment item. |
| `currency.test.network-request-count` | Debug/UI-test-only network-spy count. |

The UI test should query by identifier, wait with bounded predicate expectations (default 5 seconds, 15 seconds for initial launch), and include the identifier and current app state in failure messages. It must not use coordinates, fixed sleeps, localized text as the primary selector, or rely on field ordering.

## Assertion design by UI ID

- `UI-001`: launch `us048-zero` without `-ui-start-route`; open `character.row.currency-qa`, invoke `character.currency.open`, and assert the root, five editable fields, total, and apply action exist and become hittable after semantic scrolling.
- `UI-002`: enter `105 cp`, `11 sp`, `3 ep`, `12 gp`, `2 pp`; assert `currency.total-cp == "3565 cp"`; apply; assert field values `pp=3`, `gp=5`, `ep=1`, `sp=1`, `cp=5`.
- `UI-003`: reset for every examples-table row and assert the exact copper total plus canonical field values, including the lower-value `1 gp`, `1 sp`, and `1 cp` rows from `SC-002` even though the manual procedure summarizes them.
- `UI-004`: use `us048-existing`; capture the two equipment identifiers, enter only `250 cp`, apply, assert `2 gp + 1 ep`, relaunch without reset, assert the same balance and both equipment items.
- `UI-005`: use `us048-legacy-37-gp`; assert initial fields show `37 gp`, apply, relaunch without reset, assert `3 pp + 7 gp` and both equipment items.
- `UI-006`: use `us048-zero`; enter one of every denomination and assert exactly `11.61 gp` in English or `11,61 gp` in Spanish.
- `UI-007`: reset `us048-five-gp` before each invalid row (`-1 cp`, `1.5 gp`, `coins` in pp); attempt apply; assert the localized whole-nonnegative validation message; relaunch without reset and assert `5 gp` and equipment remain unchanged.
- `UI-008`: use `us048-five-gp`; enter the agreed boundary fixture value `Int64.max / 1000 + 1` in pp (`9223372036854776`) and apply; assert the localized amount-too-large message, no saved confirmation, then relaunch and assert `5 gp` and equipment remain unchanged. This value assumes the accepted implementation uses signed 64-bit copper storage; if the Coder selects a different safe integer type, the Specifier must approve and document the exact boundary before QA implementation changes this datum.
- `UI-009`: use `us048-zero`; assert localized title, full denomination labels, total reference label, validation copy exposed as accessibility help/value, and apply label against the expected locale table; enter `25 sp`, apply, assert `2 gp + 1 ep`; assert network count `0`; relaunch without reset and repeat balance and network-count assertions.

Expected locale strings must be asserted from an explicit QA table, not by comparing English and Spanish for inequality:

| Meaning | English (`en_US`) | Spanish (`es_ES`) |
| --- | --- | --- |
| Title | `Currency` | `Monedas` |
| cp label | `Copper (cp)` | `Cobre (cp)` |
| sp label | `Silver (sp)` | `Plata (sp)` |
| ep label | `Electrum (ep)` | `Electro (ep)` |
| gp label | `Gold (gp)` | `Oro (gp)` |
| pp label | `Platinum (pp)` | `Platino (pp)` |
| Total label | `Total in gp` | `Total en gp` |
| Apply | `Apply to character` | `Aplicar al personaje` |
| Invalid input | `Coin counts must be nonnegative whole numbers.` | `Las cantidades de monedas deben ser números enteros no negativos.` |
| Overflow | `The amount is too large.` | `La cantidad es demasiado grande.` |

If product copy differs before coding is complete, the Specifier must update the accepted expectation and this table together; QA must not infer translations from implementation output.

## Automation boundary

Automatable with the required seams:

- opening and operating all five fields and apply action;
- exact copper and gp displays, canonical normalization, invalid/overflow rejection;
- saved balance and equipment equality across a true process relaunch;
- all four device/locale combinations, localized expected strings, hittability, and scroll reachability;
- app-level offline behavior through a rejecting network dependency and request counter.

Retain as manual evidence in the canonical procedure/run record:

- visual judgment that typography is not truncated and content does not overlap at all Dynamic Type sizes; XCUITest existence/hittability/frame checks are useful but not proof of visual quality;
- external confirmation that the simulator/host network is physically disconnected, because the deterministic spy proves only that app dependencies attempted zero requests;
- human review of Spanish wording quality (automation proves exact approved copy, not linguistic quality).

Take an `XCTAttachment` screenshot after the converter opens and after save/error for each required environment. Screenshots supplement assertions and do not turn an unexecuted or failed assertion into a pass.

## Execution command design

At execution time, first discover actual UDIDs, boot each selected device, and wait for boot completion. Then run the named test plan/class with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. Example per-environment command shape (replace `<UDID>`, `<ENV>`, and timestamp only after discovery):

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project TTRPGCharacterForge.xcodeproj \
  -scheme TTRPGCharacterForge \
  -destination 'platform=iOS Simulator,id=<UDID>' \
  -only-testing:TTRPGCharacterForgeUITests/US048CurrencyConverterUITests \
  -resultBundlePath '/tmp/US-048-<timestamp>-<ENV>.xcresult'
```

The QA execution handoff must record the expanded command, resolved model/runtime/UDID, exit status, each test's actual result, `.xcresult` path, attachment names, and the run record path. Compilation, boot, launch, and test execution remain separate statuses.

## Design risks and required Coder handoff

- Add the bounded launch configuration, guarded file-backed UI-test store/reset/fixture seeding, deterministic start route, rejecting network spy/count, and accessibility identifiers above.
- Keep fixture/reset/network code unavailable to normal Release launches and preserve the offline-first production composition.
- Confirm the signed integer type used for copper totals. `UI-008` cannot use a different overflow boundary without an accepted-spec update.
- The app currently has no currency route, so production UI structure may affect how equipment is revisited. Preserve semantic accessibility identifiers even if the visual layout changes.
- Required iOS 17.5 simulator availability is unverified because CoreSimulatorService was unavailable during design. This is an execution-environment risk, not a passing or failing result.
