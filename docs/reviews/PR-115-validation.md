# PR #115 validation record

Later [red–green–refactor execution](PR-115-red-green-refactor.md) recorded an actual failing boundary test, four passing domain tests after correction, and the same four passing after refactoring in a temporary macOS XCTest harness. Final iOS app/test-bundle compilation and strict lint pass. iOS runtime execution remains blocked; the host evidence applies only to the four ability tests.

Latest follow-up: strict lint now passes with zero findings across 84 files (`/tmp/pr115-lint-zero.json`, `/tmp/pr115-lint-zero.log`, exit 0). App and test-bundle compilation also passes (`/tmp/PR115-lint-cleanup-build.log`, exit 0). The earlier results below remain historical evidence. Runtime XCTest was not rerun during this cleanup.

The configured unused-import analyzer also passed: zero findings across 76 analyzed files, exit 0 (`/tmp/pr115-analyzer-zero.json`, `/tmp/pr115-analyzer-zero.log`). Final whitespace validation passed with `git diff --check`, exit 0.

Cleanup corrected attribute placement, argument wrapping, closure labels and preview formatting; moved the review section into the existing private view extension; extracted loading completion and spell-label helpers; and removed twenty reported unused imports. No lint rules, thresholds, exclusions or suppressions were changed for this follow-up.

Commands for the follow-up:

```sh
swiftlint lint --strict --no-cache --config .swiftlint.yml --reporter json > /tmp/pr115-lint-zero.json 2>/tmp/pr115-lint-zero.log
env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build-for-testing -project TTRPGCharacterForge.xcodeproj -scheme TTRPGCharacterForge -destination 'platform=iOS Simulator,id=711D48FF-C3B4-4A29-8940-1D0658C230BA' -derivedDataPath /tmp/PR115-DerivedData > /tmp/PR115-lint-cleanup-build.log 2>&1
swiftlint analyze --strict --config .swiftlint.yml --compiler-log-path /tmp/PR115-tests-verified.log --reporter json > /tmp/pr115-analyzer-zero.json 2>/tmp/pr115-analyzer-zero.log
```

The analyzer reads current source with the earlier complete compiler-invocation log; target and build settings are unchanged. Its sandboxed attempt was interrupted after compiler subprocess permission errors and retried outside the sandbox. Compilation caught a malformed preview initializer and an incorrect helper parameter type during cleanup; both were corrected before the successful final build.

Initial workspace: `feat/character-forge-updates`, HEAD `a94a66d`, clean worktree. Review inventory and dispositions: [PR-115.md](PR-115.md). Changes remain local; the PR body was updated only to reference issue #14 and uncheck the inaccurate lint checklist.

## Observed results

| Check | Actual result | Evidence |
| --- | --- | --- |
| Final app and XCTest bundle compilation | Passed, exit 0 (`TEST BUILD SUCCEEDED`) | `/tmp/PR115-build-iphone11.log`; `/tmp/PR115-DerivedData/Build/Products/TTRPGCharacterForge_TTRPGCharacterForge_iphonesimulator26.2-x86_64.xctestrun` |
| iPhone 17e XCTest execution | Launch stalled; interrupted, exit 73; no recorded passing methods | `/tmp/PR115-tests-verified.log`; `/tmp/PR115-Tests-Verified-20261006.xcresult` (finalization also reported an action-log error) |
| iPhone 11 XCTest execution | Launch stalled; interrupted, exit 73; summary confirms 0 passed and 1 cancellation error | `/tmp/PR115-tests-iphone11.log`; `/tmp/PR115-Tests-iPhone11-20261006.xcresult` |
| SwiftLint at original HEAD | Failed, exit 2, 42 violations | `/tmp/pr115-lint-baseline.json` |
| Final broad SwiftLint | Failed, exit 2, 29 violations; no new finding tuples compared with HEAD | `/tmp/pr115-lint-verified.json` |
| Final PDF adapter targeted lint | Passed, exit 0, zero violations after expression decomposition | `/tmp/pr115-pdf-lint.log` |
| Compiler-log unused-import analyzer | Failed, exit 2, 20 existing violations after removing two new unused imports | `/tmp/pr115-analyzer-final.json`, `/tmp/pr115-analyzer-final.log` |
| Mutation-report parser tests | Passed, exit 0, six tests | `python3 scripts/quality/test-mutation-report.py` |
| Quality/mutation shell syntax | Passed, exit 0, each script checked independently | Commands below |
| CRAP-report helper self-test | Passed, exit 0 | `/tmp/pr115-crap-report self-test` |
| Xcode project syntax / whitespace | Passed, exit 0 | `plutil -lint TTRPGCharacterForge.xcodeproj/project.pbxproj`; `git diff --check` |
| Spanish catalog consistency | Passed structural assertions: IDs, schema, classifications, numeric rules and damage dice preserved | Source comparison against HEAD; display text translated without expanding the catalog |
| Actual mutation score | Not measured; green XCTest baseline unavailable | Script now checks baseline and report outcomes; parser tests are not mutation evidence |
| Coverage / CRAP | Not measured; no green runtime result | Measured complexity alone is not CRAP |
| iPhone/iPad EN/ES UI QA | Not run; full matrix execution was not requested | No UI pass inferred from test-bundle compilation |
| PDF visual alignment | Not run | PDF/PNG attachments are configured in the XCTest regression but were not produced by a completed test run |

## Commands and destinations

Both simulator identifiers were discovered with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl list devices available` during this session. They are historical run evidence, not identifiers to reuse without discovery. Runtime: iOS 26.3; compiled simulator SDK: 26.2; deployment target remains iOS/iPadOS 17.

Final compilation (exit 0):

```sh
env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build-for-testing -project TTRPGCharacterForge.xcodeproj -scheme TTRPGCharacterForge -destination 'platform=iOS Simulator,id=711D48FF-C3B4-4A29-8940-1D0658C230BA' -derivedDataPath /tmp/PR115-DerivedData > /tmp/PR115-build-iphone11.log 2>&1
```

First finalized-source execution attempt (interrupted, exit 73):

```sh
env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project TTRPGCharacterForge.xcodeproj -scheme TTRPGCharacterForge -destination 'platform=iOS Simulator,id=9D873873-44BB-49CC-96EF-E2008EE1904E' -derivedDataPath /tmp/PR115-DerivedData -only-testing:TTRPGCharacterForgeTests -enableCodeCoverage YES -parallel-testing-enabled NO -resultBundlePath /tmp/PR115-Tests-Verified-20261006.xcresult SWIFT_TREAT_WARNINGS_AS_ERRORS=NO > /tmp/PR115-tests-verified.log 2>&1
```

Independent-device execution retry:

```sh
env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test-without-building -xctestrun /tmp/PR115-DerivedData/Build/Products/TTRPGCharacterForge_TTRPGCharacterForge_iphonesimulator26.2-x86_64.xctestrun -destination 'platform=iOS Simulator,id=711D48FF-C3B4-4A29-8940-1D0658C230BA' -only-testing:TTRPGCharacterForgeTests -parallel-testing-enabled NO -resultBundlePath /tmp/PR115-Tests-iPhone11-20261006.xcresult > /tmp/PR115-tests-iphone11.log 2>&1
```

Finalized result extraction (exit 0) confirmed zero passed tests and one infrastructure error, `Testing was canceled`; it does not represent a failing assertion:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results summary --path /tmp/PR115-Tests-iPhone11-20261006.xcresult --compact > /tmp/pr115-test-summary.json
```

Static/tool checks:

```sh
swiftlint lint --strict --no-cache --config .swiftlint.yml --reporter json > /tmp/pr115-lint-verified.json
swiftlint analyze --strict --config .swiftlint.yml --compiler-log-path /tmp/PR115-tests-verified.log --reporter json > /tmp/pr115-analyzer-final.json 2> /tmp/pr115-analyzer-final.log
python3 scripts/quality/test-mutation-report.py
zsh -n scripts/quality/run-quality.sh
zsh -n scripts/quality/run-mutation.sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swiftc -module-cache-path /tmp/pr115-swift-cache scripts/quality/crap-report.swift -o /tmp/pr115-crap-report
/tmp/pr115-crap-report self-test
plutil -lint TTRPGCharacterForge.xcodeproj/project.pbxproj
git diff --check
```

The HEAD lint comparison used a separate `/tmp/PR115-baseline` checkout generated by `git archive HEAD .swiftlint.yml TTRPGCharacterForge`; the identical lint command there wrote `/tmp/pr115-lint-baseline.json`. Comparison keys were relative file, rule ID and reason, excluding shifted line numbers.

Earlier attempts are preserved separately: `/tmp/PR115-tests.log` and `/tmp/PR115-compile.log` failed compiling newly added recovery tests against the earlier app snapshot; `/tmp/PR115-tests-final.log` failed at the PDF field dictionary type-check expression (exit 65), which was decomposed and subsequently compiled successfully. `/tmp/PR115-build-verified.log` records a rejected redundant architecture argument; the final destination-based build corrected it. These failures do not establish failing test methods.

## Regression traceability

26 new XCTest regressions are compiled, but runtime status is **Not run / no recorded execution evidence**:

| Findings | Regression scope |
| --- | --- |
| Autosave ordering/dismissal, failed completion, weak editor lifetime, direct bound edits | `CharacterPersistenceReviewTests`: direct-bound autosave, canceled in-flight save ordering, invalid completion retention, editor release, failed flush |
| Currency persistence and concurrent edits | `CharacterPersistenceReviewTests`: negative rejection, suspended currency save preserving newer edits; existing `US048CurrencyConverterTests` remains in the suite |
| Portrait path and transaction safety | `PR115StorageTests`: traversal/absolute/symlink rejection and unique replacement preservation; `CharacterPersistenceReviewTests`: failed/successful transaction ordering |
| Corrupted/unsupported payload recovery | `CharacterCorruptionRecoveryTests`: mixed collection retains stored bad record until explicit delete; unsupported schema preserves original failure |
| Grant/language reconciliation and loading cancellation | `CharacterPersistenceReviewTests`: class/background skills, race/background languages, canceled loading state |
| Ability/equipment/armor/catalog/token/PDF findings | `PR115DomainTests`: standard-array swap, point budget atomicity, partial method setup, required background equipment, positive wealth, heavy versus medium Dexterity, malformed spell catalog, unique token output, injected renderer delegation, bilingual supplied PDF templates |

The accessibility contract in `docs/sdlc/US-048/qa-design.md` now uses the seeded document UUID, matching unique production row IDs. Expected QA outcomes remain specification; no Actual result was changed into a pass.

## Routing and residual decisions

Separate Coder agents owned persistence/UI and domain/platform fixes; Cleaner owned review and behavior-preserving decomposition. Files transferred sequentially between owners. Existing acceptance requirements were retained; no new OpenSpec change was needed. Specifier was not invoked to redefine equipment bundles or minimum spell counts. Full Hardener and QA execution were not advanced on an unproven unit baseline.

Required build evidence is green. Runtime implementation verification remains blocked, so the complete SDLC/merge gate is not green. Lint and CRAP/mutation measurement were best effort for this review task; their results are reported independently.

Equipment bundle semantics need a separate accepted schema/content change. Exact minimum spell counts and asynchronous loading/actor redesign were rejected as unaccepted tightening or unmeasured performance changes. The cached seed catalog remains synchronous. Spanish translations preserve existing content rather than claiming a complete human-reviewed SRD dataset. Portrait cleanup after a successful record deletion is best effort; it does not turn a committed delete into a reported record-delete failure.

## Review 5431152311: explicit Combine imports

Restored `import Combine` in `SpellListViewModel`, `CharacterEditorVM`, and `CharacterListViewModel` for their `ObservableObject` and `@Published` declarations. This addresses new comment 4197529038 and related existing comments 4040894131 and 4040894162. No behavior changed; runtime tests were not run for this import-only correction.

Validation on 2026-10-06:

- `git diff --check`: exit 0.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build-for-testing -project TTRPGCharacterForge.xcodeproj -scheme TTRPGCharacterForge -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PR115-Combine-Review-20261006 CODE_SIGNING_ALLOWED=NO`: exit 65; sandbox CoreSimulator access failed. Log: `/tmp/PR115-Combine-Review-20261006.log`.
- Approved retry: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build-for-testing -project TTRPGCharacterForge.xcodeproj -scheme TTRPGCharacterForge -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PR115-Combine-Review-Verified-20261006 CODE_SIGNING_ALLOWED=NO`: exit 0, `TEST BUILD SUCCEEDED`. Log: `/tmp/PR115-Combine-Review-Verified-20261006.log`. This proves app and test-bundle compilation, not runtime test execution.

## Review 5431448930: rulesets, duplicate skills, and spell loading

Addressed new inline comment 4197779820 and the two newly reported review-body findings:

- Store decoding rejects unsupported `rulesetID` values after either supported date format is decoded. The original record remains visible as unreadable, with an explicit localized English/Spanish error; direct fetch also rejects it.
- Completion rejects duplicate skill IDs before counting distinct class selections, including duplicated background skills.
- A serial worker queue performs spell catalog loading and mapping off the main thread. Success and failure completions return on the main queue.

Regression mappings: `UT-PR115-RULESET` -> `testUnsupportedRulesetRemainsUnreadableForBothDateFormats`; `UT-PR115-SKILLS` -> `testCompletionRejectsDuplicateSkillSelections`; `UT-PR115-SPELL-THREAD` -> `testSpellLoadingRunsOffMainAndDeliversResultsOnMain`.

Executed on 2026-10-06:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project TTRPGCharacterForge.xcodeproj -scheme TTRPGCharacterForge -destination 'platform=iOS Simulator,id=711D48FF-C3B4-4A29-8940-1D0658C230BA' -derivedDataPath /tmp/PR115-Combine-Review-Verified-20261006 -only-testing:TTRPGCharacterForgeTests/CharacterCorruptionRecoveryTests -only-testing:TTRPGCharacterForgeTests/PR115DomainTests/testCompletionRejectsDuplicateSkillSelections -resultBundlePath /tmp/PR115-Ruleset-Red-20261006.xcresult CODE_SIGNING_ALLOWED=NO
```

Exit 65: test compilation exposed an initializer argument-order error, which was corrected. Log: `/tmp/PR115-Ruleset-Red-20261006.log`. Retried the same command with `Red2` replacing `Red` in the result/log paths. Exit 73 after interruption: no test methods executed; this is not red regression evidence.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project TTRPGCharacterForge.xcodeproj -scheme TTRPGCharacterForge -destination 'platform=iOS Simulator,id=711D48FF-C3B4-4A29-8940-1D0658C230BA' -derivedDataPath /tmp/PR115-Combine-Review-Verified-20261006 -parallel-testing-enabled NO -only-testing:TTRPGCharacterForgeTests/CharacterCorruptionRecoveryTests -only-testing:TTRPGCharacterForgeTests/PR115DomainTests -only-testing:TTRPGCharacterForgeTests/PR115StorageTests -resultBundlePath /tmp/PR115-Review-Green-20261006.xcresult CODE_SIGNING_ALLOWED=NO
```

Exit 73 after interruption: compilation completed, but simulator test execution stalled before any test methods ran. Log: `/tmp/PR115-Review-Green-20261006.log`. The simulator ID was discovered live with `simctl list devices booted`; it is evidence for this run only.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path /tmp/PR115-Review-Host-20261006
```

Exit 0: seven macOS XCTest tests ran and passed, including all three new regression methods. Log: `/tmp/PR115-Review-Host-20261006.log`. This temporary macOS 14 package copies the repository's domain, storage, and spell repository sources; recovery/storage tests use the repository test methods. The duplicate-skill fixture loads the same bundled English JSON by filesystem path because the harness is not the app bundle. This is host execution evidence, not an iOS XCTest pass.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build-for-testing -project TTRPGCharacterForge.xcodeproj -scheme TTRPGCharacterForge -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PR115-Combine-Review-Verified-20261006 CODE_SIGNING_ALLOWED=NO
git diff --check
python3 -m json.tool TTRPGCharacterForge/Localizable.xcstrings
```

All exited 0. Build result: `TEST BUILD SUCCEEDED`. Log: `/tmp/PR115-Review-Build-20261006.log`; parsed localization artifact: `/tmp/PR115-review-localizations.json`. No UI QA, coverage, CRAP, or mutation result is claimed for this focused correction.

Replied to carried-over comments 4040673038, 4040672749, and 4039250142: explicit `AbilityID: Hashable`, Spanish catalog locale `es`, and awaited `flushAutosave()` already address their claims. Equipment schema semantics and obsolete cache cleanup remain separate carried-over items; this patch does not claim to resolve them.
