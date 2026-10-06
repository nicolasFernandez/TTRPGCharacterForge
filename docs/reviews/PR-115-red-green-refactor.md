# PR #115 red–green–refactor evidence

Scope: accepted point-buy budget, including the exact 27-point boundary. This is an explicit controlled regression replay of an existing implementation, not a claim that historical fixes were developed test-first.

Coder added `UT-PR115-POINTBUY-27`, `PR115DomainTests/testPointBuyAllowsExactlyTwentySevenPoints`. Intelligence 9→10 takes the fixture from 26 to 27 points; assertions verify complete scores, assignment method, identity, name and completion validation. Existing tests cover overspending without document mutation, standard-array swaps and incremental method changes. Cleaner extracted `validatePointBuyBudget` after observed GREEN, preserving default-zero partial assignments and atomic rejection. No acceptance criteria or assertions were weakened.

| Phase | Actual runtime result | Evidence |
| --- | --- | --- |
| RED: temporary `cost < 27` regression | Exit 1; four XCTest methods executed, boundary test failed with `invalidAbilityScores`, other three passed | `/tmp/PR115-RGR-Host-Red.log` |
| GREEN: restore `cost <= 27` | Exit 0; four XCTest methods passed | `/tmp/PR115-RGR-Host-Green.log` |
| REFACTOR: extract budget helper | Exit 0; same four XCTest methods passed | `/tmp/PR115-RGR-Host-Refactor.log` |
| Final strict lint | Exit 0; zero findings across 84 files | `/tmp/PR115-RGR-Final-Lint.json`, `/tmp/PR115-RGR-Final-Lint.log` |
| Final iOS app and test-bundle compilation | Exit 0; `TEST BUILD SUCCEEDED` | `/tmp/PR115-RGR-Final-Build.log` |
| iOS focused RED execution attempt | Launch stalled after test-bundle compilation; interrupted, exit 73; no observed test method execution | `/tmp/PR115-RGR-Red.log`, `/tmp/PR115-RGR-Red.xcresult` |

Runtime test evidence is **macOS XCTest for domain logic**. A temporary SwiftPM package copies all current Domain sources and the required `String+Utils.swift`, with the exact first four test methods from `PR115DomainTests.swift`. No production logic is mocked or reimplemented. The package does not verify SwiftUI, SwiftData, PDF rendering, simulator integration or the full iOS suite. The separate Swift Testing runner's zero-test footer is not the evidence; the XCTest suite explicitly executed four methods.

Harness preparation is `/tmp/PR115-RGR-prepare.py`; package and executable are under `/tmp/PR115-RGR-Host`. The initial harness build omitted the string utility dependency and failed compilation; adding the existing utility resolved that harness error before the recorded RED run.

Exact runtime commands (executed sequentially with the relevant production source snapshot refreshed before each phase):

```sh
python3 /tmp/PR115-RGR-prepare.py
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path /tmp/PR115-RGR-Host --filter PR115DomainTests > /tmp/PR115-RGR-Host-Red.log 2>&1
cp TTRPGCharacterForge/Domain/UseCases/UpdateAbilityScoreUseCase.swift /tmp/PR115-RGR-Host/Sources/TTRPGCharacterForge/UpdateAbilityScoreUseCase.swift
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path /tmp/PR115-RGR-Host --filter PR115DomainTests > /tmp/PR115-RGR-Host-Green.log 2>&1
python3 /tmp/PR115-RGR-prepare.py
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path /tmp/PR115-RGR-Host --filter PR115DomainTests > /tmp/PR115-RGR-Host-Refactor.log 2>&1
```

iPhone 11 identifier was discovered during this turn; `simctl bootstatus` confirmed ready, exit 0. Historical destination commands:

```sh
env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project TTRPGCharacterForge.xcodeproj -scheme TTRPGCharacterForge -destination 'platform=iOS Simulator,id=711D48FF-C3B4-4A29-8940-1D0658C230BA' -derivedDataPath /tmp/PR115-DerivedData -only-testing:TTRPGCharacterForgeTests/PR115DomainTests/testPointBuyAllowsExactlyTwentySevenPoints -parallel-testing-enabled NO -resultBundlePath /tmp/PR115-RGR-Red.xcresult > /tmp/PR115-RGR-Red.log 2>&1
env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build-for-testing -project TTRPGCharacterForge.xcodeproj -scheme TTRPGCharacterForge -destination 'platform=iOS Simulator,id=711D48FF-C3B4-4A29-8940-1D0658C230BA' -derivedDataPath /tmp/PR115-DerivedData > /tmp/PR115-RGR-Final-Build.log 2>&1
swiftlint lint --strict --no-cache --config .swiftlint.yml --reporter json > /tmp/PR115-RGR-Final-Lint.json 2>/tmp/PR115-RGR-Final-Lint.log
```

Ownership: Coder owned the dirty test and use-case files during RED/GREEN; after GREEN passed, ownership of the use-case alone transferred to Cleaner. Root owned execution and this report. All pre-existing changes were preserved. Required gates: observed domain RED/GREEN/refactor and strict lint. CRAP is not measured; no same-run coverage was collected. Mutation score is not measured; one deliberately killed boundary regression is not a full mutation campaign. Specifier, Hardener and UI QA were skipped because this request concerns a bounded existing domain rule.

Measured complexity: `updatedScores` decreased from 4 to 2; extracted `validatePointBuyBudget` is 3. Existing `AbilityAssignmentService.validate` remains 5. Commands were `swift-complexity TTRPGCharacterForge/Domain/UseCases/UpdateAbilityScoreUseCase.swift --format json --threshold 0`, both exit 1 because the reporting threshold is zero, with JSON artifacts `/tmp/PR115-RGR-Complexity-Before.json` and `/tmp/PR115-RGR-Complexity-After.json`. These measurements are not CRAP. Final `git diff --check` passed, exit 0.
