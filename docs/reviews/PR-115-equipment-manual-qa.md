# PR-115 starting equipment manual QA

## Document control

| Field | Value |
| --- | --- |
| User story | US-PR115-EQUIPMENT |
| Source | https://github.com/nicolasFernandez/TTRPGCharacterForge/pull/115#pullrequestreview-5432038382, comment 4038268257 |
| Scenarios | [PR-115-equipment.feature](PR-115-equipment.feature) |
| Build/commit, tester, date/time | Not run |

## Test environment

| Field | Value |
| --- | --- |
| Device, OS/runtime, app version/build | Not run |
| Locale, network state, data/reset state | Not run |

Preconditions for every case: create a fresh level-1 character with all non-equipment choices valid, a background with required equipment, and that background equipment selected. Start with zero starting gold. Select equipment using the creation wizard, attempt completion using its final action, and observe completion or equipment validation feedback. Keep unrelated choices unchanged.

## Cases

| Case / traces | Priority | Human actions and data | Expected result | Actual result | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| QA-PR115-EQ-01 / AC-PR115-EQ-01, SC-PR115-EQ-01 | High | Select fighter, martial weapon and shield. Attempt completion separately with chain mail, leather armor, both armors, and neither armor. | Each single armor permits completion. Both or neither produce equipment validation feedback. | Not run | Not run | Not run |
| QA-PR115-EQ-02 / AC-PR115-EQ-02, SC-PR115-EQ-02 | High | For fighter select chain mail; for paladin select javelin. Attempt completion with martial weapon plus shield, then with each member alone. | Complete bundle permits completion for both classes. Each incomplete bundle produces equipment validation feedback. | Not run | Not run | Not run |
| QA-PR115-EQ-03 / AC-PR115-EQ-03, SC-PR115-EQ-03 | High | Select barbarian and explorer's pack. Attempt completion with greataxe only, both greataxe and martial weapon, martial weapon only, then remove explorer's pack. | Either single weapon with pack permits completion. Both weapons or missing pack produce equipment validation feedback. | Not run | Not run | Not run |
| QA-PR115-EQ-04 / AC-PR115-EQ-04, SC-PR115-EQ-04 | High | Select fighter and enter 1 starting gold. Leave class equipment unselected, attempt completion, then remove required background equipment and retry. | Positive gold permits completion without class equipment. Missing required background equipment produces equipment validation feedback. | Not run | Not run | Not run |
| QA-PR115-EQ-05 / AC-PR115-EQ-05, SC-PR115-EQ-05 | Medium | Disable network. In English create fighter with chain mail, martial weapon, shield and background equipment. Save draft, terminate and reopen app, open draft and complete. Repeat in Spanish with a fresh character. | All equipment selections persist after relaunch, names use the selected language, and completion succeeds offline in both languages. | Not run | Not run | Not run |
| QA-PR115-EQ-06 / AC-PR115-EQ-06, SC-PR115-EQ-06 | High | Open a prepared duplicate-equipment draft fixture containing fighter chain mail, martial weapon, shield twice, and required background equipment; attempt completion through the wizard. | Repeated equipment selections produce equipment validation feedback. Fixture preparation is a test precondition because ordinary UI toggles cannot create duplicate IDs. | Not run | Not run | Not run |

## Implementation contract

Represent each class group as `EquipmentChoiceGroup(options: [[String]])`: one inner array is the complete required bundle for one option, and exactly one option must be satisfied per group when positive wealth does not bypass class choices. Reject partial bundles, mixed alternatives, and duplicate selected IDs. Fighter armor options are `[["chain-mail"], ["leather-armor"]]`; fighter and paladin weapon/shield options are `[["martial-weapon", "shield"]]`. Convert other existing seed alternatives into singleton options. Preserve allowed-item and background validation before the positive-wealth bypass, including existing currency precedence and negative-currency rejection. Character persistence continues to store plain equipment IDs; no document migration is needed. Catalog version may increase to 2 for the changed class representation; English and Spanish must expose identical option IDs and semantics. Do not add item quantities, full SRD alternatives, or new equipment IDs.

## Run notes

- Defect IDs: None recorded.
- Accessibility, localization observations, cleanup/reset: Not run.
