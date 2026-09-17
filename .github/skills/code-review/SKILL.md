---
  name: code-review
  description: Review pull requests for authorization, data exposure, migration safety, maintainability, test effectiveness, lint/static quality, CRAP, and mutation-test gaps.
---

  # Repository review workflow

  Review the diff and surrounding code before making recommendations. Do not approve, merge, or silently change production behavior.

  ## Security and persistence

  1. Identify changed trust boundaries, authorization checks, persisted-data formats, and migration paths.
  2. Check authorization before every new read or write path.
  3. Check for accidental data exposure, insecure logging, secrets, and unsafe defaults.
  4. For schema or persistence changes, require:
     - forward migration steps;
     - rollback or recovery steps;
     - compatibility handling for existing data;
     - tests for malformed, legacy, and unsupported data.
  5. Preserve established public contracts and accepted scenarios. Route functional corrections to the coder and acceptance-criteria changes to the specifier.

  ## Maintainability and cleanup

  1. Inspect concurrency, persistence, architecture boundaries, duplication, naming, localization, accessibility, and error handling.
  2. Run configured formatters, linters, and static analyzers. Do not install new tools without authorization.
  3. Use behavior-preserving cleanup only when supported by evidence.
  4. Record findings with file and line evidence, ranked by impact.
  5. Report unavailable measurements as `not measured`, including the missing tool or artifact.

  For this repository, use:

  ```bash
  scripts/quality/run-quality.sh
  ```
  Keep build success, test-bundle compilation, test execution, coverage, CRAP, and mutation results as separate evidence. Never infer one from another.

  ## Test effectiveness and mutation hardening

  1. Match behavior changes to focused tests, including negative and persistence/migration cases.
  2. Read the accepted scenarios, implementation diff, Cleaner metrics, and current tests.
  3. Restrict mutation analysis to eligible in-scope production logic. Exclude generated code, UI declarations, resources, and third-party code.
  4. Establish a green baseline using the same build environment before mutation testing.
  5. Run the configured mutation command separately:
 ```bash
  scripts/quality/run-mutation.sh '<file-or-glob>'
```
  6. Do not install a mutation framework or change dependencies without authorization.
  7. For each survivor, classify it as:
      - missing assertion or case;
      - equivalent mutant;
      - unreachable code;
      - tooling limitation.

  8. Add focused tests for meaningful survivors when test ownership permits. Route production refactors to the Cleaner and functional corrections to the Coder.
  9. Do not exclude difficult mutants merely to improve the score. Every exclusion requires a path/symbol, reason, and approval or established repository policy.

  Mutation targets:

  - eligible in-scope mutants: 100% killed;
  - timeout, compile error, or tool crash: not a killed mutant unless the tool explicitly classifies it as killed;
  - mandatory mutation tooling unavailable: status blocked, never passed.

  ## CRAP analysis

  Use cyclomatic complexity and line/branch coverage from the same test run and report:

  CRAP(m) = complexity(m)^2 * (1 - coverage(m))^3 + complexity(m)

  Normalize coverage to 0...1. For every measured method, report:

  - source and method;
  - complexity;
  - coverage;
  - CRAP score;
  - whether it meets CRAP <= 4.

  Never substitute file coverage, guessed complexity, build success, or lint results. A method with complexity above 4 cannot meet the gate even with full coverage and must be
  simplified or reported.

  ## Review result

  Return an evidence-based handoff containing:

  - review status: pass, findings, blocked, or not measured;
  - ranked findings with file/line evidence;
  - authorization and data-exposure assessment;
  - migration forward/rollback assessment;
  - tests reviewed and missing cases;
  - exact commands, destinations, exit statuses, and artifact paths;
  - lint/static results;
  - baseline mutation result;
  - generated, killed, survived, excluded counts and score;
  - survivor dispositions;
  - per-method CRAP results;
  - fixes made, if any;
  - residual risks and requested follow-up.

  Do not claim a quality gate passed unless the corresponding command and evidence exist.
