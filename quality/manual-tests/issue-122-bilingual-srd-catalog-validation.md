# Issue #122 bilingual SRD catalog validation manual QA procedure

## Document control

| Field | Value |
| --- | --- |
| User story | `US-122` |
| Source | GitHub issue #122; `SRD_CC_v5.1.pdf`; `SRD_CC_v5.1_ES.pdf` |
| Acceptance artifact | `quality/features/issue-122-bilingual-srd-catalog-validation.feature` |
| Catalog revisions | Not run |
| Build/commit | Not run |
| Reviewer/tester | Not run |
| Date/time | Not run |

## Test environment

| Field | Value |
| --- | --- |
| Device | Repository review: local Mac; app checks: supported iPhone and iPad |
| OS/runtime | Repository review: Not run; app checks: iOS/iPadOS 17, Not run |
| App version/build | Not run |
| Locale | `en` and `es`; app checks use `en_US` and `es_ES` |
| Network state | Catalog review is local-only; app checks use offline mode |
| Data/reset state | Clean review ledger generated from the exact catalog revisions under review |

## Controlled inputs and review record

Use these fixed source pairs; do not substitute an online rules source during this review.

| Locale | Catalog | Authoritative review input |
| --- | --- | --- |
| `en` | `TTRPGCharacterForge/Data/Local/rules_en.json` | `SRD_CC_v5.1.pdf` |
| `es` | `TTRPGCharacterForge/Data/Local/rules_es.json` | `SRD_CC_v5.1_ES.pdf` |

Create a review ledger in the run evidence directory. CSV or JSON is acceptable if it can be deterministically sorted and counted. It must contain one record per `(locale, section, entryID)` and at least these fields:

- catalog revision/commit, locale, section, entry ID, and field path;
- catalog before value and accepted after value;
- field disposition: `verified`, `corrected`, `not-applicable`, or `unresolved`;
- source filename plus PDF page number and named section or table;
- discrepancy ID and rationale when the disposition is not `verified`;
- reviewer, review timestamp, focused validation/test ID, and validation result.

An entry is `reviewed` only when every applicable name, description, ID, cross-reference, and rule-value field has a final `verified` or accepted `corrected` disposition. A field marked `not-applicable` needs a reason. Any `unresolved` or missing field disposition leaves the entry unreviewed.

Use this deterministic inventory command from the repository root and preserve its output as run evidence:

```sh
jq -r '[input_filename, .locale, (.races|length), (.classes|length), (.backgrounds|length), (.skills|length), (.languages|length), (.equipment|length), (.spells|length), ([.races,.classes,.backgrounds,.skills,.languages,.equipment,.spells]|map(length)|add)] | @tsv' TTRPGCharacterForge/Data/Local/rules_en.json TTRPGCharacterForge/Data/Local/rules_es.json
```

Generate the entry key set used for one-to-one ledger accounting with:

```sh
jq -r '.locale as $locale | ["races","classes","backgrounds","skills","languages","equipment","spells"][] as $section | .[$section][] | [$locale,$section,.id] | @tsv' TTRPGCharacterForge/Data/Local/rules_en.json TTRPGCharacterForge/Data/Local/rules_es.json | LC_ALL=C sort
```

The current counts are test data, not execution evidence: each catalog contains 9 races, 12 classes, 1 background, 18 skills, 16 languages, 27 equipment entries, and 6 spells, for 89 entries per locale and 178 bilingual entry records. Recompute rather than assuming these counts during a run.

## Discrepancy and correction workflow

1. Assign a stable discrepancy ID to every mismatch, dangling reference, missing bilingual pair, or unsupported value.
2. Record the exact JSON field path, before value, source citation, and proposed after value. Do not overwrite the evidence of the original mismatch.
3. If the two supplied PDFs disagree on a shared ID or non-localized rule value, cite both. Do not choose a winner unless an authorized source-precedence decision exists.
4. If translated wording differs, do not assume literal wording or semantic equivalence is preferred. Record the case as unresolved unless an authorized translation policy decides it.
5. After an accepted catalog correction, add or update focused catalog-validation/localization coverage, execute it, and attach the result to the ledger record.
6. Re-run full schema, ID uniqueness, bilingual pairing, and cross-reference checks. Only then may the corrected field be final.
7. Release readiness requires zero unreviewed entries and zero unresolved discrepancies.

## QA-122-01: Inventory and account for every catalog entry

- Traces to: `AC-122-01`, `SC-122-01`
- Priority: critical
- Preconditions: repository checkout and `jq` are available; the two catalogs are fixed to recorded revisions.
- Test data: all seven catalog sections in both locale files.

| Step | Human action | Expected result | Actual result | Status | Evidence |
| ---: | --- | --- | --- | --- | --- |
| 1 | Record the commit and checksums of both catalogs and both supplied PDFs. | The exact four inputs can be reproduced and no online source is required. | Not run | Not run | Not run |
| 2 | Run the inventory-count command and save its unedited output. | One row per catalog reports every section count and a total. | Not run | Not run | Not run |
| 3 | Run the entry-key command and save its sorted output. | Every `(locale, section, entryID)` appears exactly once. | Not run | Not run | Not run |
| 4 | Check for blank IDs, duplicate keys, and ledger keys absent from or missing from the generated key set. | Blank IDs, duplicates, extras, and omissions are zero; otherwise each is an unresolved discrepancy. | Not run | Not run | Not run |

## QA-122-02: Review every English field against the English SRD

- Traces to: `AC-122-02`, `SC-122-02`
- Priority: critical
- Preconditions: `QA-122-01` inventory exists and the English PDF page numbering convention is recorded.
- Test data: every English inventory key, processed in sorted section/ID order.

| Step | Human action | Expected result | Actual result | Status | Evidence |
| ---: | --- | --- | --- | --- | --- |
| 1 | Open `SRD_CC_v5.1.pdf` and the English catalog side by side. | The review uses only the recorded local inputs. | Not run | Not run | Not run |
| 2 | For each English key, locate the matching rule, table, or section and record its PDF page and named section. | Every record has reproducible provenance or an unresolved source-location discrepancy. | Not run | Not run | Not run |
| 3 | Compare every applicable name, description, ID, cross-reference, and rule-value field. | Each field is `verified`, `corrected`, `not-applicable` with reason, or `unresolved`; no field is silently skipped. | Not run | Not run | Not run |
| 4 | Reconcile the ledger keys and completed dispositions with the English inventory. | Reviewed plus unreviewed equals the English inventory total, with counts by section. | Not run | Not run | Not run |

## QA-122-03: Review every Spanish field against the Spanish SRD

- Traces to: `AC-122-02`, `SC-122-02`
- Priority: critical
- Preconditions: `QA-122-01` inventory exists and the Spanish PDF page numbering convention is recorded.
- Test data: every Spanish inventory key, processed in sorted section/ID order.

| Step | Human action | Expected result | Actual result | Status | Evidence |
| ---: | --- | --- | --- | --- | --- |
| 1 | Open `SRD_CC_v5.1_ES.pdf` and the Spanish catalog side by side. | The review uses only the recorded local inputs. | Not run | Not run | Not run |
| 2 | For each Spanish key, locate the matching rule, table, or section and record its PDF page and named section. | Every record has reproducible provenance or an unresolved source-location discrepancy. | Not run | Not run | Not run |
| 3 | Compare every applicable name, description, ID, cross-reference, and rule-value field. | Each field is `verified`, `corrected`, `not-applicable` with reason, or `unresolved`; no field is silently skipped. | Not run | Not run | Not run |
| 4 | Reconcile the ledger keys and completed dispositions with the Spanish inventory. | Reviewed plus unreviewed equals the Spanish inventory total, with counts by section. | Not run | Not run | Not run |

## QA-122-04: Verify bilingual pairing and all catalog cross-references

- Traces to: `AC-122-04`, `SC-122-04`
- Priority: critical
- Preconditions: `QA-122-02` and `QA-122-03` ledgers exist.
- Test data: paired English/Spanish entry keys and every ID-valued field or option in both catalogs.

| Step | Human action | Expected result | Actual result | Status | Evidence |
| ---: | --- | --- | --- | --- | --- |
| 1 | Compare the sorted section/ID sets between locales. | Missing or extra locale pairs are zero, or each is an unresolved discrepancy. | Not run | Not run | Not run |
| 2 | Compare paired entries' stable IDs and non-localized rule values. | Shared identifiers and mechanics are compatible, or differences have cited discrepancy records. | Not run | Not run | Not run |
| 3 | Resolve every referenced skill, language, equipment, class, feature, option, or other ID against the intended same-locale catalog/domain vocabulary. | No reference is dangling or silently redirected; unsupported references are unresolved. | Not run | Not run | Not run |
| 4 | Compare localized names and descriptions to the respective PDF citations, not to each other alone. | Both localized forms have independent provenance and dispositions. | Not run | Not run | Not run |

## QA-122-05: Record, correct, and validate each discrepancy

- Traces to: `AC-122-03`, `AC-122-05`, `AC-122-06`, `SC-122-03`, `SC-122-05`, `SC-122-06`
- Priority: critical
- Preconditions: discrepancy records from the field and pairing reviews exist, or a zero-discrepancy ledger is recorded.
- Test data: every discrepancy ID; every accepted correction; both complete catalogs.

| Step | Human action | Expected result | Actual result | Status | Evidence |
| ---: | --- | --- | --- | --- | --- |
| 1 | Inspect each discrepancy record for before value, proposed after value, field path, locale, entry ID, and citation. | Every discrepancy is reproducible and no original mismatch evidence is lost. | Not run | Not run | Not run |
| 2 | For a cross-source disagreement, verify that both citations and the authorized disposition are recorded. | No source or translation priority is invented; without authorization the item stays unresolved. | Not run | Not run | Not run |
| 3 | Inspect each accepted correction's focused catalog/localization test mapping and execute the documented targeted checks. | Each corrected field is exercised by an executed check; compilation alone is not a pass. | Not run | Not run | Not run |
| 4 | Execute the documented full-catalog schema, uniqueness, pairing, and cross-reference checks. | Both complete catalogs pass, with exact commands, exit statuses, and artifacts recorded. | Not run | Not run | Not run |

## QA-122-06: Confirm corrected catalog behavior offline in both locales

- Traces to: `AC-122-07`, `SC-122-07`
- Priority: high
- Preconditions: a build containing accepted catalog corrections; deterministic level-1 fixture; device network disabled; app data reset.
- Test data: one corrected or explicitly verified representative from each affected section, in English and Spanish.

| Step | Human action | Expected result | Actual result | Status | Evidence |
| ---: | --- | --- | --- | --- | --- |
| 1 | Launch the app offline in English and navigate through the rules-driven level-1 character flow using the test entries. | The bundled English entries, choices, references, and values are available without a network request. | Not run | Not run | Not run |
| 2 | Relaunch offline in Spanish and repeat with the paired entries. | The bundled Spanish entries, choices, references, and values are available without a network request. | Not run | Not run | Not run |
| 3 | Compare the visible localized data and resulting shared mechanics with the accepted ledger records. | Localized text matches its accepted source record and shared mechanics remain compatible. | Not run | Not run | Not run |

## QA-122-07: Prove release-readiness accounting

- Traces to: `AC-122-08`, `SC-122-08`
- Priority: critical
- Preconditions: all review, correction, focused validation, full-catalog validation, and offline evidence is collected.
- Test data: final inventory, ledger, discrepancy register, and validation artifacts for the exact catalog revisions.

| Step | Human action | Expected result | Actual result | Status | Evidence |
| ---: | --- | --- | --- | --- | --- |
| 1 | Produce reviewed, unreviewed, corrected, and unresolved counts by locale and section from the ledger. | Each category is measurable and reviewed plus unreviewed equals inventory for every section. | Not run | Not run | Not run |
| 2 | Compare the final ledger key set with the deterministic catalog key set. | There are no missing, duplicate, or extra records. | Not run | Not run | Not run |
| 3 | Confirm every correction links to passing focused and full-catalog validation evidence. | No corrected record relies on source inspection or compilation alone. | Not run | Not run | Not run |
| 4 | Evaluate the release gate. | English unreviewed = 0, Spanish unreviewed = 0, unresolved discrepancies = 0, and exact revisions/evidence paths are identified; otherwise the gate fails. | Not run | Not run | Not run |

## Traceability matrix

| Acceptance criterion | Scenario | Manual QA coverage |
| --- | --- | --- |
| `AC-122-01` | `SC-122-01` | `QA-122-01` |
| `AC-122-02` | `SC-122-02` | `QA-122-02`, `QA-122-03` |
| `AC-122-03` | `SC-122-03` | `QA-122-05` |
| `AC-122-04` | `SC-122-04` | `QA-122-04` |
| `AC-122-05` | `SC-122-05` | `QA-122-05` |
| `AC-122-06` | `SC-122-06` | `QA-122-05` |
| `AC-122-07` | `SC-122-07` | `QA-122-06` |
| `AC-122-08` | `SC-122-08` | `QA-122-07` |

## Open product decision

- No accepted policy currently states which supplied source wins if the English and Spanish SRDs disagree on a shared identifier or non-localized rule value, or whether translated prose must be literal versus semantically equivalent. The review can inventory and document these cases, but affected entries must remain unresolved until an authorized disposition is recorded. This decision can block catalog corrections and V1 release readiness; it must not be inferred by the reviewer.

## Run notes

- Defect IDs: None
- Accessibility observations: Not run
- Localization observations: Not run
- English catalog review: Not run
- Spanish catalog review: Not run
- Catalog/localization validation: Not run
- Offline iPhone check: Not run
- Offline iPad check: Not run
- Cleanup/reset performed: Not run
