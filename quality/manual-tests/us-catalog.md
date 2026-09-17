# US-prefixed story catalogue manual QA

## Document control

| Field | Value |
| --- | --- |
| User stories | `US-001`–`US-064` (existing plus proposed gaps) |
| Source | `SRD_CC_v5.1.pdf`; `SRD_CC_v5.1_ES.pdf`; GitHub US-prefixed issues |
| Build/commit | Not run |
| Tester | Not run |
| Date/time | Not run |

## Test environment

| Field | Value |
| --- | --- |
| Device | Not run; execute on supported iPhone and iPad |
| OS/runtime | Not run; iOS/iPadOS 17 |
| App version/build | Not run |
| Locale | `en_US` and `es_ES` |
| Network state | Not run; include offline cases for local-first stories |
| Data/reset state | Not run; use isolated fixtures per story |

## Procedure

Each numeric story has a corresponding QA case (`QA-001` through `QA-064`) and traces to
the scenario with the same suffix in `quality/features/us-catalog.feature`. The compact
table below defines the deterministic procedure shared by those cases; actual result and
status intentionally remain `Not run`.

| QA | Traces to | Human action | Expected result | Actual result | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| QA-001–QA-051 | `US-001`–`US-051` (one case per suffix) | Execute the primary user journey described by the matching scenario in the feature file. | The matching scenario passes using the cited SRD source where applicable. | Not run | Not run | Not run |
| QA-052–QA-057 | `US-052`–`US-057` (one case per suffix) | Execute only after the proposed story is accepted and its SRD page/section references are recorded. | The accepted proposed behavior passes in English and Spanish. | Not run | Not run | Not run |
| QA-058–QA-064 | `US-058`–`US-064` (one case per suffix) | Run the documented repository quality or CI command and inspect its artifact. | The command reports the configured gate accurately; unavailable tooling is not treated as a pass. | Not run | Not run | Not run |

## Refinement decisions and open questions

- `US-001` is retained for traceability but is closed and architectural rather than SRD behavior.
- `US-005` is the parent story for `US-034`–`US-036`; child stories must not redefine score rules.
- `US-007` coordinates derived values; `US-017`, `US-038`, `US-039`, and `US-040` provide focused slices.
- `US-019` and `US-049` overlap; decide whether `US-019` is the journey-level umbrella and `US-049` the control-level slice.
- `US-016`, `US-017`, `US-023`, and `US-024` are future/server or multi-system scope and must not weaken the offline-first D&D 5e MVP.
- `US-032` is retained as the networking boundary: unavailable remote services must leave the bundled SRD flow and local drafts usable.
- `US-013` and `US-015` are mobile-contract stories; backend implementation and provider secrets are out of scope for this repository.
- `US-045` is proposed from the unnumbered class-detail issue #27. `US-052`–`US-057` are proposed gaps identified by comparing the issue inventory with level-one SRD coverage.
- “Both directions” and “inventory update” in `US-048` require product confirmation before implementation-bound scenarios are expanded.

## Run notes

- Defect IDs: None
- Accessibility observations: Not run
- Localization observations: Not run
- SRD English/Spanish human review: Not run
- Cleanup/reset performed: Not run
