#!/usr/bin/env python3
"""Regression tests for Muter16 report gating; no mutation run is performed."""
import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("mutation-report.py")
spec = importlib.util.spec_from_file_location("mutation_report", SCRIPT)
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)


def fixture():
    # Identity matches Muter16's official regression JSON serialization.
    return {
        "globalMutationScore": 100,
        "totalAppliedMutationOperators": 1,
        "numberOfKilledMutants": 1,
        "fileReports": [{
            "fileName": "Example.swift", "mutationScore": 100,
            "appliedOperators": [{
                "mutationPoint": {
                    "mutationOperatorId": "RemoveSideEffects",
                    "position": {"line": 63, "column": 41}
                },
                "testSuiteOutcome": "failed"
            }]
        }]
    }


class MutationGateTests(unittest.TestCase):
    def test_measured_failure_passes(self):
        self.assertEqual(gate.validate(fixture()), 1)

    def test_survivor_fails_even_with_false_summary(self):
        report = fixture()
        report["fileReports"][0]["appliedOperators"][0]["testSuiteOutcome"] = "passed"
        report["numberOfKilledMutants"] = 0
        with self.assertRaisesRegex(gate.GateError, "surviving"):
            gate.validate(report)

    def test_empty_and_unknown_schema_fail(self):
        for report in ({}, [], {"totalAppliedMutationOperators": 0}, None):
            with self.subTest(report=report), self.assertRaises(gate.GateError):
                gate.validate(report)

    def test_execution_errors_and_unknown_outcomes_fail(self):
        for outcome in ("buildError", "runtimeError", "noCoverage", "timeout", None):
            report = fixture()
            report["fileReports"][0]["appliedOperators"][0]["testSuiteOutcome"] = outcome
            with self.subTest(outcome=outcome), self.assertRaises(gate.GateError):
                gate.validate(report)

    def test_missing_identity_or_inconsistent_counts_fail(self):
        reports = []
        report = fixture()
        report["fileReports"][0]["appliedOperators"][0]["mutationPoint"] = {}
        reports.append(report)
        report = fixture()
        report["totalAppliedMutationOperators"] = 2
        reports.append(report)
        report = fixture()
        report["numberOfKilledMutants"] = 0
        reports.append(report)
        report = fixture()
        report["globalMutationScore"] = 99
        reports.append(report)
        for report in reports:
            with self.subTest(report=report), self.assertRaises(gate.GateError):
                gate.validate(report)

    def test_cli_exit_status_for_pass_invalid_json_and_missing_report(self):
        with tempfile.TemporaryDirectory() as directory:
            report = Path(directory) / "report.json"
            report.write_text(json.dumps(fixture()))
            self.assertEqual(subprocess.run([sys.executable, str(SCRIPT), str(report)], capture_output=True).returncode, 0)
            report.write_text("invalid json")
            self.assertNotEqual(subprocess.run([sys.executable, str(SCRIPT), str(report)], capture_output=True).returncode, 0)
            report.unlink()
            self.assertNotEqual(subprocess.run([sys.executable, str(SCRIPT), str(report)], capture_output=True).returncode, 0)


if __name__ == "__main__":
    unittest.main()
