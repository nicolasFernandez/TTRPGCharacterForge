#!/usr/bin/env python3
"""Fail-closed gate for the JSON emitted by Muter release 16.

Schema verified against official tag 16, TestReporting/MuterTestReport.swift
and TestReporting/TestSuiteOutcome.swift. `passed` means mutant survived.
Runtime errors are rejected even though Muter includes them in killed totals:
an infrastructure failure is not evidence of an effective assertion.
"""
import argparse
import json
import sys
from pathlib import Path


class GateError(ValueError):
    """Missing, inconsistent, unmeasured or unsuccessful mutation evidence."""


def integer(report, key):
    value = report.get(key)
    if type(value) is not int or value < 0:
        raise GateError(f"Invalid or absent {key}")
    return value


def validate(report):
    if not isinstance(report, dict):
        raise GateError("Unknown report schema: expected Muter16 object")
    total = integer(report, "totalAppliedMutationOperators")
    killed = integer(report, "numberOfKilledMutants")
    score = integer(report, "globalMutationScore")
    files = report.get("fileReports")
    if total == 0 or not isinstance(files, list) or not files:
        raise GateError("No measured mutants")
    outcomes = []
    for file_report in files:
        if not isinstance(file_report, dict) or not isinstance(file_report.get("fileName"), str):
            raise GateError("Unknown file report schema")
        operators = file_report.get("appliedOperators")
        if not isinstance(operators, list) or not operators:
            raise GateError(f"No measured mutants in {file_report['fileName']}")
        integer(file_report, "mutationScore")
        for operator in operators:
            if not isinstance(operator, dict) or not isinstance(operator.get("mutationPoint"), dict):
                raise GateError("Unknown applied operator schema")
            point = operator["mutationPoint"]
            position = point.get("position")
            if not isinstance(point.get("mutationOperatorId"), str) or not point["mutationOperatorId"]:
                raise GateError("Missing mutation operator identity")
            if not isinstance(position, dict) or integer(position, "line") == 0:
                raise GateError("Missing measured mutation position")
            integer(position, "column")
            outcome = operator.get("testSuiteOutcome")
            if outcome not in {"passed", "failed", "buildError", "runtimeError", "noCoverage"}:
                raise GateError(f"Unknown mutation outcome: {outcome!r}")
            outcomes.append(outcome)
    if len(outcomes) != total:
        raise GateError("Applied mutant count does not match file reports")
    if killed != sum(outcome in {"failed", "runtimeError"} for outcome in outcomes):
        raise GateError("Killed mutant count does not match outcomes")
    survivors = outcomes.count("passed")
    if survivors:
        raise GateError(f"{survivors} unexplained surviving mutant(s); inspect report")
    if any(outcome != "failed" for outcome in outcomes):
        raise GateError("Unmeasured or failed mutation execution (coverage/build/runtime)")
    if killed != total or score != 100:
        raise GateError("Summary contradicts measured outcomes")
    if any(file_report["mutationScore"] != 100 for file_report in files):
        raise GateError("File mutation score contradicts measured outcomes")
    return total


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", type=Path)
    args = parser.parse_args()
    try:
        count = validate(json.loads(args.report.read_text()))
    except (OSError, ValueError, TypeError, KeyError) as error:
        print(f"Mutation gate failed: {error}", file=sys.stderr)
        return 1
    print(f"Mutation gate passed: {count} measured mutants killed by failing tests")
    return 0


if __name__ == "__main__":
    sys.exit(main())
