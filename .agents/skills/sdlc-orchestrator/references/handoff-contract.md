# SDLC handoff contract

Every delegated role returns these fields:

```markdown
## <Role> handoff

- Status: completed | passed | failed | blocked | not-run
- Scope: <requirement and scenario IDs>
- Inputs: <files and prior handoffs used>
- Files changed: <paths or none>
- Commands run: <exact commands or none>
- Results: <exit status and measured values>
- Evidence: <report, xcresult, log, screenshot, or source paths>
- Risks or assumptions: <items or none>
- Next role: <role and requested action, or none>
```

## Status semantics

- `completed`: the role produced and validated its artifacts but had no runtime quality check to execute.
- `passed`: the role's required runtime checks executed successfully and evidence is named.
- `failed`: a check executed and demonstrated a defect or missed threshold.
- `blocked`: required input, authorization, environment, or tooling prevents meaningful completion.
- `not-run`: execution was not requested or has not happened. It is never synonymous with passed.

## Traceability IDs

Use stable IDs across artifacts:

- user story: `US-<number>`
- acceptance criterion: `AC-<number>`
- Gherkin scenario: `SC-<number>`
- manual QA case: `QA-<number>`
- unit test: `UT-<number>` in comments or the handoff map
- UI test: `UI-<number>` in comments or the handoff map

Do not rename an accepted ID silently. Record superseded IDs when requirements change.

## Shared-worktree ownership

The orchestrator assigns one writer for each file. Agents may inspect any relevant file but must not revert or overwrite changes made by other agents or the user. If an unexpected overlapping edit appears, stop writing that file and notify the orchestrator.

Use this manifest shape in delegation messages:

| Path | Owner | Allowed editors | Phase | Dirty before orchestration |
| --- | --- | --- | --- | --- |
| `<path>` | `<role>` | `<roles or none>` | `<phase>` | yes/no |
