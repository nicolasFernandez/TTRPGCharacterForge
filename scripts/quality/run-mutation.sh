#!/bin/zsh

set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

if ! command -v muter >/dev/null 2>&1; then
  print -u2 "Missing prerequisite: muter. See README.md#quality-tooling."
  exit 2
fi

timestamp="$(date -u +%Y-%m-%dT%H%M%SZ)"
artifact_root="${QUALITY_ARTIFACT_DIR:-.quality-artifacts/$timestamp}"
mutation_report="$artifact_root/muter.json"
version_report="$artifact_root/tool-versions.txt"
files_to_mutate="${1:-TTRPGCharacterForge/Domain/**/*.swift}"

mkdir -p "$artifact_root"
muter --version > "$version_report"

muter \
  --configuration muter.conf.yml \
  --files-to-mutate "$files_to_mutate" \
  --format json \
  --output "$mutation_report" \
  --skip-update-check

print "Mutation report: $mutation_report"
