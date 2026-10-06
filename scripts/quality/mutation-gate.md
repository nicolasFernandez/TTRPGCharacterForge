# Mutation report gate

`run-mutation.sh` first requires an unmodified unit-test baseline and then runs
Muter. Its final Python gate validates the JSON format emitted by installed
Muter release **16**, including per-mutant identities and outcomes and aggregate
count consistency. A Muter exit code of zero alone does not pass this gate.

The automated gate passes only a nonempty measured run in which every mutant
has `testSuiteOutcome: failed` and every score is 100. Muter's `passed` outcome
means the mutant survived. Build errors, runtime errors, missing coverage,
unknown outcomes/schema, empty reports, inconsistent counts, and unreadable or
invalid JSON all fail. Runtime errors are deliberately rejected even though
Muter itself counts them as kills; they need investigation before being treated
as test effectiveness evidence.

Equivalent mutants and tool limitations must be documented with the exact
report artifact, file, operator, line/column, source revision, reasoning, and
reviewer decision. There is no automatic exception switch or broad exclusion
list. Such a reviewed exception remains visible as a failed automated gate;
record any accepted manual quality decision separately and never claim 100%
measured mutation effectiveness for it.

Run parser checks without executing mutation testing:

```sh
python3 scripts/quality/test-mutation-report.py
```

Verified upstream schema sources:

- [Muter16 report fields and serialization](https://github.com/muter-mutation-testing/muter/blob/16/Sources/muterCore/TestReporting/MuterTestReport.swift)
- [Muter16 outcome meanings](https://github.com/muter-mutation-testing/muter/blob/16/Sources/muterCore/TestReporting/TestSuiteOutcome.swift)
- [Muter16 official JSON regression report](https://github.com/muter-mutation-testing/muter/blob/16/RegressionTests/__Snapshots__/RegressionTests/test_bonMot.bonmot.json)
