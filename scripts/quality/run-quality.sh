#!/bin/zsh

set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/tmp/TTRPGCharacterForge-SwiftModuleCache}"
export SWIFT_MODULECACHE_PATH="${SWIFT_MODULECACHE_PATH:-$CLANG_MODULE_CACHE_PATH}"
mkdir -p "$CLANG_MODULE_CACHE_PATH"

for tool in xcodebuild xcrun swiftc swift-complexity swiftlint; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    print -u2 "Missing prerequisite: $tool. See README.md#quality-tooling."
    exit 2
  fi
done

timestamp="$(date -u +%Y-%m-%dT%H%M%SZ)"
artifact_root="${QUALITY_ARTIFACT_DIR:-.quality-artifacts/$timestamp}"
complexity_scope="${QUALITY_COMPLEXITY_PATH:-TTRPGCharacterForge/Domain}"
result_bundle="$artifact_root/UnitTests.xcresult"
coverage_report="$artifact_root/xccov.json"
complexity_report="$artifact_root/swift-complexity.json"
crap_report="$artifact_root/crap.md"
crap_executable="$artifact_root/crap-report"
version_report="$artifact_root/tool-versions.txt"

mkdir -p "$artifact_root"

{
  xcodebuild -version
  swiftlint version
  swift-complexity --version
} > "$version_report"

QUALITY_RESULT_BUNDLE_PATH="$result_bundle" scripts/quality/run-unit-tests.sh
xcrun xccov view --report --json "$result_bundle" > "$coverage_report"

set +e
swift-complexity "$complexity_scope" --recursive --format json > "$complexity_report"
complexity_status=$?
set -e

if [[ ! -s "$complexity_report" ]]; then
  print -u2 "swift-complexity did not produce a report (exit $complexity_status)."
  exit 2
fi

set +e
swiftlint lint --strict --config .swiftlint.yml --reporter xcode
lint_status=$?
set -e

swiftc scripts/quality/crap-report.swift -o "$crap_executable"

set +e
"$crap_executable" "$complexity_report" "$coverage_report" 4 > "$crap_report"
crap_status=$?
set -e

print "Quality artifacts: $artifact_root"
print "SwiftLint exit status: $lint_status"
print "swift-complexity exit status: $complexity_status"
print "CRAP report exit status: $crap_status"

if (( lint_status != 0 || complexity_status != 0 || crap_status != 0 )); then
  exit 1
fi
