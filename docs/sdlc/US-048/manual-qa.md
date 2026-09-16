# US-048 Currency converter manual QA procedure

## Document control

| Field | Value |
| --- | --- |
| User story | `US-048` |
| Source | [GitHub issue #14](https://github.com/nicolasFernandez/TTRPGCharacterForge/issues/14) |
| Specification | `docs/sdlc/US-048/US-048.feature` |
| Build/commit | Not run |
| Tester | Not run |
| Date/time | Not run |

## Acceptance criteria and assumptions

| ID | Acceptance criterion |
| --- | --- |
| `AC-001` | A selected character has a currency converter with fields for cp, sp, ep, gp, and pp. |
| `AC-002` | Conversions use exact integer copper arithmetic with `cp=1`, `sp=10`, `ep=50`, `gp=100`, and `pp=1000`. |
| `AC-003` | Values entered in any denomination are converted bidirectionally and normalized in pp, gp, ep, sp, cp order without losing value. |
| `AC-004` | Applying a conversion replaces and persists the selected character's currency balance; legacy `startingWealthGP` appears as gp and migrates on save; selected equipment is unchanged. |
| `AC-005` | The exact total is shown as a localized gp reference. |
| `AC-006` | Negative, fractional, nonnumeric, or overflowing inputs are rejected atomically without changing the saved balance. |
| `AC-007` | Conversion and persistence work without a network connection. |
| `AC-008` | User-facing converter content is localized in English and Spanish and usable on iPhone and iPad. |

The source story does not define the editor interaction, normalization policy, numeric bounds, gp formatting, or how currency relates to the existing character model. For this conservative MVP, “inventory” means a persisted five-denomination currency balance on the character, applying replaces the balance, inputs are nonnegative whole coin counts, canonical normalization is greedy `pp -> gp -> ep -> sp -> cp`, calculations use an exact integer copper base, overflow is rejected without state change, and legacy gp wealth seeds the new balance. These assumptions do not alter selected equipment.

## Test environment

| Field | Value |
| --- | --- |
| Device | Not run; execute on one supported iPhone and one supported iPad simulator/device |
| OS/runtime | Not run; iOS/iPadOS 17.x |
| App version/build | Not run |
| Locale | Not run; execute in English and Spanish |
| Network state | Not run; offline except where a case says otherwise |
| Data/reset state | Not run; use deterministic local fixtures described by each case |

## Required execution matrix

| Matrix ID | Device class | Locale | Runtime | Network | Actual result | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `ENV-001` | iPhone | English | iOS 17.x | Offline | Not run | Not run | Not run |
| `ENV-002` | iPhone | Spanish | iOS 17.x | Offline | Not run | Not run | Not run |
| `ENV-003` | iPad | English | iPadOS 17.x | Offline | Not run | Not run | Not run |
| `ENV-004` | iPad | Spanish | iPadOS 17.x | Offline | Not run | Not run | Not run |

Run `QA-001`, `QA-005`, and `QA-009` across all four environments. Run the remaining cases on at least one iPhone environment, repeating any locale-sensitive assertion in both English and Spanish.

## QA-001: Open the five-denomination converter

- Traces to: `AC-001`, `SC-001`
- Priority: critical
- Environments: `ENV-001`, `ENV-002`, `ENV-003`, `ENV-004`
- Preconditions: A locally stored character is selected.
- Test data: Character `Currency QA`, with zero currency and a known equipment selection.

| Step | Human action | Expected result | Actual result | Status | Evidence |
| ---: | --- | --- | --- | --- | --- |
| 1 | Navigate to the selected character's currency converter. | The converter opens for `Currency QA` and shows editable cp, sp, ep, gp, and pp coin fields. | Not run | Not run | Not run |
| 2 | Inspect the full converter and scroll if needed. | All fields, the total-gp reference, and the apply action are visible, readable, and operable without clipping or overlap. | Not run | Not run | Not run |

## QA-002: Normalize mixed SRD denominations exactly

- Traces to: `AC-002`, `AC-003`, `SC-001`
- Priority: critical
- Environments: `ENV-001`
- Preconditions: `Currency QA` is selected and its converter is open.
- Test data: `105 cp`, `11 sp`, `3 ep`, `12 gp`, `2 pp`.

| Step | Human action | Expected result | Actual result | Status | Evidence |
| ---: | --- | --- | --- | --- | --- |
| 1 | Enter the test data in the five matching fields. | Every nonnegative whole value is accepted. | Not run | Not run | Not run |
| 2 | Invoke the converter/apply action. | The normalized balance is `3 pp, 5 gp, 1 ep, 3 sp, 5 cp`; its exact value is `3585 cp`. | Not run | Not run | Not run |

## QA-003: Convert in higher and lower directions

- Traces to: `AC-002`, `AC-003`, `SC-002`
- Priority: critical
- Environments: `ENV-001`
- Preconditions: `Currency QA` is selected and its converter is open; clear all fields before each row.
- Test data: Rows below.

| Step | Human action | Expected result | Actual result | Status | Evidence |
| ---: | --- | --- | --- | --- | --- |
| 1 | Enter `10 cp` and apply. | Balance normalizes to `1 sp`; total remains exactly `10 cp`. | Not run | Not run | Not run |
| 2 | Enter `10 sp` and apply. | Balance normalizes to `1 gp`; total remains exactly `100 cp`. | Not run | Not run | Not run |
| 3 | Enter `2 ep` and apply. | Balance normalizes to `1 gp`; total remains exactly `100 cp`. | Not run | Not run | Not run |
| 4 | Enter `10 gp` and apply. | Balance normalizes to `1 pp`; total remains exactly `1000 cp`. | Not run | Not run | Not run |
| 5 | Enter `1 pp` and apply. | The exact `1000 cp` value is represented and can be expressed as `10 gp`, `100 sp`, or `1000 cp`; the persisted canonical balance is `1 pp`. | Not run | Not run | Not run |

## QA-004: Persist a converted balance without changing equipment

- Traces to: `AC-004`, `SC-003`
- Priority: critical
- Environments: `ENV-001`
- Preconditions: `Currency QA` has `1 pp, 2 gp, 0 ep, 3 sp, 4 cp` and a recorded equipment selection; note the equipment list before starting.
- Test data: `250 cp`, all other coin fields zero.

| Step | Human action | Expected result | Actual result | Status | Evidence |
| ---: | --- | --- | --- | --- | --- |
| 1 | Enter the test data and apply it to the character. | The visible balance normalizes to `0 pp, 2 gp, 1 ep, 0 sp, 0 cp`. | Not run | Not run | Not run |
| 2 | Navigate away, terminate the app, relaunch it while offline, and reopen the same character's converter. | The normalized balance remains `0 pp, 2 gp, 1 ep, 0 sp, 0 cp`. | Not run | Not run | Not run |
| 3 | Inspect the character's equipment. | The equipment selection exactly matches the list recorded before the conversion. | Not run | Not run | Not run |

## QA-005: Migrate legacy gp wealth

- Traces to: `AC-004`, `SC-004`
- Priority: critical
- Environments: `ENV-001`, `ENV-002`, `ENV-003`, `ENV-004`
- Preconditions: Load a backward-compatible local fixture whose only money value is legacy starting wealth `37 gp`; it has no five-denomination balance and has a known equipment selection.
- Test data: Legacy wealth `37 gp`.

| Step | Human action | Expected result | Actual result | Status | Evidence |
| ---: | --- | --- | --- | --- | --- |
| 1 | Open the legacy character's converter. | It displays `0 pp, 37 gp, 0 ep, 0 sp, 0 cp`; no value is lost. | Not run | Not run | Not run |
| 2 | Apply the displayed balance, terminate the app, relaunch offline, and reopen the converter. | The persisted canonical balance displays `3 pp, 7 gp, 0 ep, 0 sp, 0 cp`. | Not run | Not run | Not run |
| 3 | Inspect the character's equipment. | Its selected equipment is unchanged from the fixture. | Not run | Not run | Not run |

## QA-006: Display an exact localized gp reference

- Traces to: `AC-005`, `SC-005`
- Priority: high
- Environments: `ENV-001`, `ENV-002`
- Preconditions: `Currency QA` is selected and its converter is open.
- Test data: `1 cp`, `1 sp`, `1 ep`, `1 gp`, `1 pp` = `1161 cp`.

| Step | Human action | Expected result | Actual result | Status | Evidence |
| ---: | --- | --- | --- | --- | --- |
| 1 | In English, enter the test data. | The total reference displays exactly `11.61 gp`. | Not run | Not run | Not run |
| 2 | Repeat in Spanish. | The total reference displays exactly `11,61 gp`; labels and supporting text are Spanish. | Not run | Not run | Not run |

## QA-007: Reject invalid input atomically

- Traces to: `AC-006`, `SC-006`
- Priority: critical
- Environments: `ENV-001`, `ENV-002`
- Preconditions: The character's saved balance is `5 gp`, known equipment is recorded, and the converter is open.
- Test data: `-1 cp`, `1.5 gp`, and `coins` in pp, tested separately.

| Step | Human action | Expected result | Actual result | Status | Evidence |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | Enter `-1` in cp and attempt to apply. | A localized message requires nonnegative whole coin counts; the saved `5 gp` balance and equipment remain unchanged. | Not run | Not run | Not run |
| 2 | Restore the form, enter `1.5` in gp, and attempt to apply. | A localized message requires nonnegative whole coin counts; the saved `5 gp` balance and equipment remain unchanged. | Not run | Not run | Not run |
| 3 | Restore the form, enter `coins` in pp, and attempt to apply. | A localized message requires nonnegative whole coin counts; the saved `5 gp` balance and equipment remain unchanged. | Not run | Not run | Not run |

## QA-008: Reject overflow atomically

- Traces to: `AC-006`, `SC-007`
- Priority: critical
- Environments: `ENV-001`
- Preconditions: The character's saved balance is `5 gp`, known equipment is recorded, and the converter is open.
- Test data: A whole pp count at the maximum accepted input boundary, plus one, such that multiplication by `1000 cp` cannot be represented safely by the app's integer amount type.

| Step | Human action | Expected result | Actual result | Status | Evidence |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | Enter the overflowing pp value and attempt to apply. | A localized “amount too large” message appears; no partial result is shown as saved. | Not run | Not run | Not run |
| 2 | Navigate away and reopen the converter. | The saved balance is still `5 gp`; equipment is unchanged. | Not run | Not run | Not run |

## QA-009: Convert and persist offline in both locales and device classes

- Traces to: `AC-007`, `AC-008`, `SC-008`, `SC-009`
- Priority: critical
- Environments: `ENV-001`, `ENV-002`, `ENV-003`, `ENV-004`
- Preconditions: Disable network connectivity before launch; select `Currency QA`; its converter is open.
- Test data: `25 sp`, all other fields zero.

| Step | Human action | Expected result | Actual result | Status | Evidence |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | Inspect all converter content in the environment's locale. | Title, denomination labels, total reference, validation text, and apply action use the selected locale; content is not clipped or overlapping. | Not run | Not run | Not run |
| 2 | Enter `25 sp` and apply while offline. | Balance becomes `0 pp, 2 gp, 1 ep, 0 sp, 0 cp`; no network prompt or dependency appears. | Not run | Not run | Not run |
| 3 | Relaunch offline and reopen the same character. | The converted balance persists locally and remains fully operable. | Not run | Not run | Not run |

## Traceability matrix

| Acceptance criterion | Gherkin scenarios | Manual QA cases |
| --- | --- | --- |
| `AC-001` | `SC-001` | `QA-001` |
| `AC-002` | `SC-001`, `SC-002` | `QA-002`, `QA-003` |
| `AC-003` | `SC-001`, `SC-002` | `QA-002`, `QA-003` |
| `AC-004` | `SC-003`, `SC-004` | `QA-004`, `QA-005` |
| `AC-005` | `SC-005` | `QA-006` |
| `AC-006` | `SC-006`, `SC-007` | `QA-007`, `QA-008` |
| `AC-007` | `SC-008` | `QA-009` |
| `AC-008` | `SC-009` | `QA-009` |

## Run notes

- Defect IDs: None
- Accessibility observations: Not run
- Localization observations: Not run
- Cleanup/reset performed: Not run
