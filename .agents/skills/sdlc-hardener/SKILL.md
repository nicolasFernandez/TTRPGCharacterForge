---
name: sdlc-hardener
description: Challenge Swift test effectiveness with mutation testing, analyze surviving mutants, and strengthen tests while enforcing the configured CRAP threshold. Use after implementation and cleanup, especially for critical domain logic.
---

# SDLC Hardener

Assume passing tests may still be weak. Use mutation results, not confidence language, to assess them.

## Scope and baseline

Read accepted scenarios, the implementation diff, Cleaner metrics, and current tests. Restrict mutations to eligible in-scope production logic so generated code, UI declarations, resources, and third-party code do not dilute the score.

Run the repository's configured Swift mutation tool. Do not install a mutation framework or change project dependencies without authorization. First establish a green baseline using the same build environment.

For this repository, use `.swift-complexity.yml`, `.swiftlint.yml`, `muter.conf.yml`, and the scripts under `scripts/quality/`. Run `scripts/quality/run-quality.sh` for unit coverage, complexity, lint, and CRAP reporting. Run `scripts/quality/run-mutation.sh '<file-or-glob>'` separately for the explicitly selected production scope; mutation is intentionally not part of the fast quality command.

If no mutation or method-level complexity tooling is configured, report the precise missing prerequisite and a proposed setup task. A required gate is `blocked`; a best-effort gate is `not measured`. Do not silently introduce the tool as part of feature implementation.

## Targets

- Default mutation target: 100% for eligible in-scope mutants.
- Default maintainability target: CRAP `<= 4` for each measured in-scope method.
- A timeout, compile error, or tool crash is not a killed mutant unless the tool classifies it that way under its documented rules.

For every survivor, decide whether it exposes a missing assertion, missing case, equivalent mutant, unreachable code, or tooling limitation. Add focused tests to kill meaningful survivors. You may edit tests within assigned ownership; route necessary production refactors to the Cleaner and functional corrections to the Coder.

Do not exclude difficult mutants merely to raise the score. Every exclusion needs a path/symbol, reason, and approval or established repository policy.

Return the orchestrator handoff contract with tool/version, exact command, baseline result, generated/killed/survived/excluded counts, score, survivor dispositions, CRAP results, and report paths. If mutation tooling is absent, return `blocked` when mutation is mandatory; never claim the gate passed.
