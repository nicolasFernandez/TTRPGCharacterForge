@US-122
@issue-122
@offline-first
@bilingual
Feature: Validate the bundled bilingual SRD catalogs for V1
  Before V1 release, a reviewer must be able to account for every bundled
  English and Spanish catalog entry and trace each accepted value to the
  corresponding supplied SRD document. The review must not depend on a network
  service or expand the level-1 D&D 5e scope.

  Background:
    Given the review uses "TTRPGCharacterForge/Data/Local/rules_en.json" and "SRD_CC_v5.1.pdf" for English
    And the review uses "TTRPGCharacterForge/Data/Local/rules_es.json" and "SRD_CC_v5.1_ES.pdf" for Spanish
    And each review record identifies the locale, catalog section, entry ID, and source page or named section

  @AC-122-01 @SC-122-01
  Scenario: Account for the complete catalog inventory before review
    When the reviewer creates the review inventory from every entry in races, classes, backgrounds, skills, languages, equipment, and spells
    Then the inventory records the per-section and total entry counts for each locale
    And every catalog entry is represented exactly once by locale, section, and entry ID
    And duplicate IDs, missing IDs, or an inventory count mismatch are unresolved discrepancies

  @AC-122-02 @SC-122-02
  Scenario: Verify every catalog field against its locale source
    Given an inventoried catalog entry has not yet been reviewed
    When the reviewer compares its name, description, ID, cross-references, and rule values with the corresponding locale source
    Then every applicable field is recorded as verified or corrected
    And every non-applicable field is recorded as not applicable with a reason
    And the review record cites the source document and page or named section
    And the entry is not reviewed while any applicable field lacks a disposition

  @AC-122-03 @SC-122-03
  Scenario: Record and correct a catalog discrepancy
    Given a catalog value does not match its cited locale source
    When the reviewer records the discrepancy and the proposed correction
    Then the record preserves the before value, after value, affected locale, entry ID, field path, and provenance citation
    And the entry remains unresolved until the correction and its focused validation are accepted
    And the correction does not add rules outside the offline-first level-1 D&D 5e V1 scope

  @AC-122-04 @SC-122-04
  Scenario: Validate bilingual entry pairing and cross-references
    When the reviewer compares the English and Spanish inventories
    Then each shared catalog entry has the same stable ID and compatible non-localized rule values in both locales
    And each referenced skill, language, equipment, class, or other catalog ID resolves in the same locale
    And localized names and descriptions are checked against their respective locale source
    And a missing pair, dangling reference, or incompatible shared value is an unresolved discrepancy

  @AC-122-05 @SC-122-05
  Scenario: Escalate a disagreement between the supplied sources without inventing policy
    Given the English and Spanish source documents disagree on a shared rule value or identifier
    When the reviewer cannot apply an already authorized source-precedence or translation policy
    Then the disagreement is recorded with citations to both sources
    And neither value is silently chosen as authoritative
    And the affected entries remain unresolved until an authorized disposition is recorded

  @AC-122-06 @SC-122-06
  Scenario: Cover accepted corrections with catalog and localization tests
    Given one or more catalog fields have accepted corrections
    When the catalog validation and localization checks are run
    Then focused checks cover each corrected entry and field
    And both complete catalogs pass schema, uniqueness, pairing, and cross-reference validation
    And a compiled test bundle without executed test methods is not reported as a passing result

  @AC-122-07 @SC-122-07
  Scenario: Preserve bundled catalog behavior without a network
    Given the device has no network connection
    When the English or Spanish rules-driven level-1 character flow loads corrected catalog data
    Then the applicable bundled names, descriptions, choices, cross-references, and rule values remain available
    And no network service is required to validate or use the bundled catalogs

  @AC-122-08 @SC-122-08
  Scenario: Reach zero unreviewed entries for release readiness
    Given the deterministic inventory and review records are complete
    When release readiness is evaluated
    Then the reviewed count equals the inventory count separately for English and Spanish
    And the unreviewed count is zero separately for every locale and catalog section
    And the unresolved discrepancy count is zero
    And the report identifies the exact catalog revisions and validation evidence evaluated
