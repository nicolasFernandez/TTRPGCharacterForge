# US-122 Coder handoff

- Status: blocked
- Scope: `US-122`; PR #124 findings `4220385628` and `4220385724`; `CAT-122-04`, `CAT-122-05`; `AC-122-04` / `SC-122-04`, `AC-122-06` / `SC-122-06`
- Inputs: accepted US-122 feature and manual procedure; QA design; Coder skill; orchestrator handoff contract; Cleaner NO-GO rework
- Files changed: `TTRPGCharacterForge/Domain/Entities/DamageType.swift`; `TTRPGCharacterForge/Domain/Protocols/RulesRepository.swift`; `TTRPGCharacterForge/Data/Local/rules_en.json`; `TTRPGCharacterForge/Data/Local/rules_es.json`; `TTRPGCharacterForge/Data/Firebase/BundledRulesRepository.swift`; `TTRPGCharacterForge/Data/Local/LocalSpellRepository.swift`; `TTRPGCharacterForgeTests/US122CatalogValidationTests.swift`; `docs/sdlc/US-122/coder-handoff.md`
- Results: schema `3` separates localized display strings from directly Codable canonical mechanics. Equipment now carries complete damage dice (`numberOfDice`, sides, modifier; JSON key remains `count`) and canonical damage type. Spells now carry canonical casting time, range, component set, duration, and higher-level presence. Bilingual validation compares typed equality without translation dictionaries or parsers. Single-catalog validation rejects malformed typed shapes. `LocalSpellRepository` maps components from the canonical set while preserving all display strings. CI build `37808699354` exposed an invalid `DamageType` redeclaration before tests; the duplicate catalog enum was removed and the existing app-wide `DamageType` now conforms to `Codable` and `Sendable`. Its cases cover all catalog values (`bludgeoning`, `piercing`, `slashing`). JSON structure/schema checks and strict changed-file lint passed. Runtime tests did not start because runtime-resolved simulator boot stalled and was interrupted; the required runtime gate remains blocked for CI.
- Evidence: source files above; CI build `37808699354` compile failure; no new `.xcresult` or executed-test artifact. JSON checks printed `true` for both catalogs. Final SwiftLint reported `0 violations, 0 serious` across five changed Swift files.
- Risks or assumptions: the typed values are mechanical encodings of existing bundled data, not human provenance or translation verification. Schema `3` intentionally rejects schema `2` catalogs. RED was not executed. Compilation and XCTest execution remain unproven locally.
- Next role: Cleaner re-review, then CI/Coder runtime verification of `US122CatalogValidationTests` and affected spell-domain tests.

## Traceability

| Tests | Coverage |
| --- | --- |
| `UT-122-08` | Reject canonical damage-type and full dice modifier mismatch. |
| `UT-122-09` | Reject loss from the canonical spell component set. |
| `UT-122-10` | Reject higher-level-presence mismatch. |
| `UT-122-11` | Reject numeric and category spell-range drift. |
| `UT-122-12` | Reject canonical duration and casting-time drift. |
| `UT-122-13` | Reject missing damage dice/type pairs and non-positive dice values. |
| `UT-122-14` | Reject invalid distance and non-distance range shapes. |
| `UT-122-15` | Reject invalid timed and instantaneous duration shapes. |
| `UT-122-16` | Reject empty component sets and inconsistent higher-level presence. |

## Commands and exact results

1. JSON syntax/inventory check, exit `0`:

   ```sh
   jq empty TTRPGCharacterForge/Data/Local/rules_en.json TTRPGCharacterForge/Data/Local/rules_es.json
   jq -r '[.locale,.schemaVersion,([.equipment[]|select(.damage != null)]|length),([.equipment[]|select(.damageDice != null and .damageType != null)]|length),([.spells[]|select(has("castingTimeMechanic") and has("rangeMechanic") and has("componentSet") and has("durationMechanic") and has("hasHigherLevels"))]|length)]|@tsv' TTRPGCharacterForge/Data/Local/rules_en.json TTRPGCharacterForge/Data/Local/rules_es.json
   ```

   Output: `en 3 11 11 6`; `es 3 11 11 6`.

2. Strict schema/mechanics JSON assertion, exit `0`, output `true` twice:

   ```sh
   jq empty TTRPGCharacterForge/Data/Local/rules_en.json TTRPGCharacterForge/Data/Local/rules_es.json && jq -e '(.schemaVersion == 3) and ([.equipment[] | select(.damage != null and (.damageDice == null or .damageType == null))] | length == 0) and ([.spells[] | select((has("castingTimeMechanic") and has("rangeMechanic") and has("componentSet") and has("durationMechanic") and has("hasHigherLevels")) | not)] | length == 0)' TTRPGCharacterForge/Data/Local/rules_en.json TTRPGCharacterForge/Data/Local/rules_es.json
   ```

3. Simulator discovery, exit `0`, resolved iPhone 11 `711D48FF-C3B4-4A29-8940-1D0658C230BA` on iOS 26.3:

   ```sh
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl list devices available --json
   ```

4. Simulator boot was interrupted after an excessive wait; no normal exit and no XCTest method began. Per orchestration direction, no further simulator command was attempted:

   ```sh
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl boot 711D48FF-C3B4-4A29-8940-1D0658C230BA
   ```

5. First strict lint after Cleaner rework, exit `2`: one complexity violation in `validateText(in:)`; no other violations. That method was behavior-preservingly split into typed helpers.

6. Final required strict lint, exit `0`, `0 violations, 0 serious`:

   ```sh
   swiftlint lint --strict --no-cache --config .swiftlint.yml TTRPGCharacterForge/Domain/Protocols/RulesRepository.swift TTRPGCharacterForge/Data/Firebase/BundledRulesRepository.swift TTRPGCharacterForge/Data/Local/LocalSpellRepository.swift TTRPGCharacterForgeTests/US122CatalogValidationTests.swift
   ```

7. `git diff --check`, exit `0` before the final handoff-only update; no whitespace errors.

8. CI compile-failure remediation fast checks, all exit `0`:

   ```sh
   swiftlint lint --strict --no-cache --config .swiftlint.yml TTRPGCharacterForge/Domain/Entities/DamageType.swift TTRPGCharacterForge/Domain/Protocols/RulesRepository.swift TTRPGCharacterForge/Data/Firebase/BundledRulesRepository.swift TTRPGCharacterForge/Data/Local/LocalSpellRepository.swift TTRPGCharacterForgeTests/US122CatalogValidationTests.swift
   git diff --check
   jq -e '[.equipment[].damageType // empty] | all(. == "bludgeoning" or . == "piercing" or . == "slashing")' TTRPGCharacterForge/Data/Local/rules_en.json TTRPGCharacterForge/Data/Local/rules_es.json
   ```

   SwiftLint: `0 violations, 0 serious`; catalog case check: `true` for each locale.

## Gates

- Focused/runtime XCTest: blocked; no methods executed.
- Lint: passed, strict, zero findings on changed Swift files.
- CRAP: not measured; no same-run runtime coverage is available. New helpers are below the configured complexity threshold after rework.
- Mutation: skipped; implementation uses Codable typed fields and direct equality, with no new parser/normalizer.
- UI QA: skipped; localized display behavior is preserved.
