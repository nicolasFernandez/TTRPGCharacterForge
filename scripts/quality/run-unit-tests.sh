#!/bin/zsh

set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

project_path="${QUALITY_PROJECT_PATH:-TTRPGCharacterForge.xcodeproj}"
scheme_name="${QUALITY_SCHEME:-TTRPGCharacterForgeTests}"
derived_data_path="${QUALITY_DERIVED_DATA_PATH:-/tmp/TTRPGCharacterForge-QualityDerivedData}"
enable_code_coverage="${QUALITY_ENABLE_CODE_COVERAGE:-YES}"

if [[ "$enable_code_coverage" != "YES" && "$enable_code_coverage" != "NO" ]]; then
  print -u2 "QUALITY_ENABLE_CODE_COVERAGE must be YES or NO."
  exit 2
fi

if [[ -n "${QUALITY_DESTINATION:-}" ]]; then
  destination="$QUALITY_DESTINATION"
else
  device_id="${QUALITY_DEVICE_ID:-}"

  if [[ -z "$device_id" ]]; then
    simulator_list="$(xcrun simctl list devices available)"
    device_id="$(print -r -- "$simulator_list" | sed -nE 's/^[[:space:]]*iPhone[^()]*(\([0-9A-Fa-f-]{36}\))[[:space:]]+\(Booted\).*$/\1/p' | tr -d '()' | head -1)"
  fi

  if [[ -z "$device_id" ]]; then
    device_id="$(print -r -- "$simulator_list" | sed -nE 's/^[[:space:]]*iPhone[^()]*(\([0-9A-Fa-f-]{36}\))[[:space:]]+\(Shutdown\).*$/\1/p' | tr -d '()' | head -1)"
  fi

  if [[ -z "$device_id" ]]; then
    print -u2 "No available iPhone simulator was found. Set QUALITY_DESTINATION or QUALITY_DEVICE_ID."
    exit 2
  fi

  if ! xcrun simctl list devices booted | grep -Fq "$device_id"; then
    xcrun simctl boot "$device_id"
  fi
  xcrun simctl bootstatus "$device_id" -b
  destination="platform=iOS Simulator,id=$device_id"
fi

common_arguments=(
  -project "$project_path"
  -scheme "$scheme_name"
  -destination "$destination"
  -derivedDataPath "$derived_data_path"
  -only-testing:TTRPGCharacterForgeTests
  -enableCodeCoverage "$enable_code_coverage"
  -parallel-testing-enabled NO
  SWIFT_TREAT_WARNINGS_AS_ERRORS=NO
)

build_command=(
  xcodebuild build-for-testing
  "${common_arguments[@]}"
)

test_command=(
  xcodebuild test-without-building
  "${common_arguments[@]}"
)

if [[ -n "${QUALITY_RESULT_BUNDLE_PATH:-}" ]]; then
  if [[ -e "$QUALITY_RESULT_BUNDLE_PATH" ]]; then
    print -u2 "Result bundle already exists: $QUALITY_RESULT_BUNDLE_PATH"
    exit 2
  fi
  test_command+=( -resultBundlePath "$QUALITY_RESULT_BUNDLE_PATH" )
fi

"${build_command[@]}"
"${test_command[@]}"
