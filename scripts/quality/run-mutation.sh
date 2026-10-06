#!/bin/zsh

set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

for quality_tool in muter python3; do
  if ! command -v "$quality_tool" >/dev/null 2>&1; then
    print -u2 "Missing prerequisite: $quality_tool. See README.md#quality-tooling."
    exit 2
  fi
done

timestamp="$(date -u +%Y-%m-%dT%H%M%SZ)"
artifact_root="${QUALITY_ARTIFACT_DIR:-.quality-artifacts/$timestamp}"
mutation_report="$artifact_root/muter.json"
version_report="$artifact_root/tool-versions.txt"
files_to_mutate="${1:-TTRPGCharacterForge/Domain/**/*.swift}"

mkdir -p "$artifact_root"
muter --version > "$version_report"

# Mutation results are meaningful only after the unmodified suite passes.
QUALITY_RESULT_BUNDLE_PATH="$artifact_root/Baseline.xcresult" \
  scripts/quality/run-unit-tests.sh

muter \
  --files-to-mutate "$files_to_mutate" \
  --format json \
  --output "$mutation_report" \
  --skip-update-check

python3 scripts/quality/mutation-report.py "$mutation_report"

print "Mutation report: $mutation_report"
