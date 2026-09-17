@srd-source
@source-en "SRD_CC_v5.1.pdf"
@source-es "SRD_CC_v5.1_ES.pdf"
Feature: D&D 5e character forge user-story catalogue
  This catalogue refines the current GitHub US issues into externally observable
  acceptance slices. The two SRD PDFs are authoritative for D&D rules and copy.
  Product, security, and delivery-tool choices remain explicit decisions.

  # Existing issue IDs are retained. Each slice has one criterion and one scenario
  # so later implementation and QA can extend it without renumbering.

  @US-001
  Scenario: Preserve the layered application boundary
    Given the application is built for the supported iOS and iPadOS targets
    When a feature is implemented
    Then domain rules remain independent of SwiftUI and persistence frameworks

  @US-002
  Scenario: Create an empty character draft
    Given the user starts character creation
    When the creation form opens
    Then a new editable draft is shown with no selected race, class, or background

  @US-003
  Scenario: Persist characters
    Given the user has an editable character
    When the user saves it
    Then the same character can be loaded later with its data unchanged
    And the persistence mechanism is documented as an explicit product decision

  @US-004
  Scenario: Authenticate without exposing credentials
    Given authentication is enabled for a deployment
    When an unauthenticated user starts the app
    Then the app obtains an anonymous session or displays a localized failure
    And no credential or provider secret is stored in the iOS repository

  @US-005
  Scenario: Assign ability scores using an accepted method
    Given the user selects point-buy or standard array
    When valid SRD ability scores are assigned
    Then the form shows the assignment and rejects invalid totals or duplicates
    # Detailed rules must cite the supplied SRD PDFs before acceptance.

  @US-006
  Scenario: Choose SRD race class and background
    Given the bundled 2014 SRD catalogue is loaded
    When the user chooses a race, class, and background
    Then only catalogue entries and valid choices from the source PDFs are offered

  @US-007
  Scenario: Show derived character values
    Given valid ability scores and class choices
    When the character is recalculated
    Then modifiers, hit points, proficiencies, and traits match the cited SRD rules

  @US-008
  Scenario: Autosave an edited character
    Given a saved draft is open
    When the user changes an editable field
    Then the change is persisted without an explicit save tap

  @US-009
  Scenario: Render a character sheet
    Given a valid character
    When the sheet is opened
    Then the character data is readable and no required field is silently omitted

  @US-010
  Scenario: Export the required PDF sheets
    Given a valid character and locale
    When the user exports the sheet
    Then a PDF is produced using the required bundled filenames
    And English uses 2014_EN_Character_Sheet.pdf and Spanish uses 2014_ES_Character_Sheet.pdf

  @US-011
  Scenario: Export VTT-compatible JSON
    Given a valid character
    When the user exports JSON
    Then the file contains stable character data and documented VTT-compatible fields

  @US-012
  Scenario: Share an exported character
    Given an exported character file exists
    When the user invokes the system share action
    Then the file is offered through supported iOS sharing destinations

  @US-013
  Scenario: Request an optional AI portrait
    Given the user opts into portrait generation
    When a request is submitted
    Then the mobile client uses the approved backend proxy contract
    And the app remains usable when the service is unavailable

  @US-014
  Scenario: Export a circular transparent VTT token
    Given a portrait exists
    When the user exports a token
    Then a circular transparent PNG is produced with the required crop

  @US-015
  Scenario: Regenerate or edit an optional portrait
    Given an existing portrait
    When the user requests regeneration or editing
    Then the replacement is previewed before persistence
    And the mobile contract does not add provider secrets to this repository

  @US-016
  Scenario: Resolve the SRD rules storage decision
    Given rules are required by the app
    When the storage architecture is selected
    Then the decision documents whether remote storage is allowed without violating offline-first behavior

  @US-017
  Scenario: Validate and calculate a character
    Given a character is submitted for validation
    When validation runs
    Then invalid SRD choices are rejected with user-facing localized feedback
    And the execution boundary (device or backend) is documented

  @US-018
  Scenario: Use rules while offline
    Given the device has no network connection
    When the user opens the rules-driven character flow
    Then bundled or previously cached rules remain available

  @US-019
  Scenario: Operate the app with VoiceOver and Dynamic Type
    Given accessibility services or larger text are enabled
    When the user completes a character journey
    Then controls have meaningful labels, focus order, and readable layout

  @US-020
  Scenario: Use dark mode and a custom theme
    Given the system appearance changes
    When the app is displayed
    Then content remains legible and the selected theme persists

  @US-021
  Scenario: Zoom and pan a rendered sheet
    Given a character sheet is open
    When the user zooms or pans
    Then sheet content remains navigable without changing character data

  @US-022
  Scenario: Identify the game system
    Given a character document is saved
    When it is reopened
    Then its game-system identifier is explicit and backward-compatible

  @US-023
  Scenario: Store rules for multiple systems
    Given multiple systems are enabled by an accepted product decision
    When a ruleset is loaded
    Then its data is isolated from other systems and the selected system is visible

  @US-024
  Scenario: Create a sheet for a selected game system
    Given more than one accepted game system is available
    When the user creates a sheet
    Then only rules and exports for the selected system are used

  @US-025
  Scenario: Duplicate a character as a template
    Given a saved character exists
    When the user duplicates it
    Then a new editable identity is created without mutating the original

  @US-026
  Scenario: Export all characters as a ZIP
    Given multiple saved characters exist
    When the user exports all characters
    Then one archive contains the requested per-character exports

  @US-027
  Scenario: Import a character from JSON
    Given a valid supported JSON file
    When the user imports it
    Then a draft is created and invalid or unsupported data is rejected safely

  @US-028
  Scenario: Verify domain rules with unit tests
    Given domain use cases and SRD rules are implemented
    When the unit suite runs
    Then valid, invalid, boundary, and localization cases are reported separately from UI tests

  @US-029
  Scenario: Run development services with emulators
    Given a developer enables emulator mode
    When persistence or networking is exercised
    Then requests target the emulator and production endpoints remain untouched

  @US-030
  Scenario: Distribute a beta build through TestFlight
    Given release checks have passed
    When a beta is distributed
    Then the build, release notes, and supported device/locale matrix are identifiable

  @US-031
  Scenario: Keep a temporary character draft
    Given the user has started but not completed a character
    When the app is closed and reopened
    Then the draft is recoverable locally without requiring a network

  @US-032
  Scenario: Handle optional network services without weakening offline mode
    Given a feature requests a remote service
    When the service is unavailable or the device is offline
    Then the app reports a localized failure or uses the bundled local path
    And no unrelated SRD choices or draft data are lost

  @US-033
  Scenario: Open the initial character flow
    Given the app has launched
    When the user chooses character creation
    Then race, class, and name entry are reachable from the initial flow

  @US-034
  Scenario: Configure point-buy scores
    Given point-buy is selected
    When the user assigns scores
    Then the remaining budget and SRD bounds are shown and enforced

  @US-035
  Scenario: Configure standard-array scores
    Given standard array is selected
    When the user assigns the array
    Then each value is used once and invalid assignments are rejected

  @US-036
  Scenario: Configure manual or random scores
    Given the accepted assignment mode permits manual or random scores
    When scores are produced
    Then the result is visible, reproducible where required, and validated against the accepted SRD policy

  @US-037
  Scenario: Generate a race-appropriate random name
    Given a race is selected
    When the user requests a random name
    Then a non-empty name is proposed without overwriting an accepted name

  @US-038
  Scenario: Configure armor class
    Given armor and ability choices are valid
    When derived defenses are shown
    Then armor class follows the applicable SRD formula and modifiers

  @US-039
  Scenario: Apply race speed
    Given a race is selected
    When movement is displayed
    Then the speed matches the authoritative SRD entry and locale

  @US-040
  Scenario: Apply class saving throws
    Given a class is selected
    When proficiencies are displayed
    Then saving-throw proficiencies match the authoritative SRD entry

  @US-041
  Scenario: List armor
    Given the equipment catalogue is loaded
    When the user filters for armor
    Then each listed item exposes the authoritative name and relevant rules data

  @US-042
  Scenario: List weapons
    Given the equipment catalogue is loaded
    When the user filters for weapons
    Then each listed item exposes the authoritative name and relevant rules data

  @US-043
  Scenario: Manage character inventory
    Given a character exists
    When equipment is added or removed
    Then the inventory and character export reflect the change without losing unrelated choices

  @US-044
  Scenario: View race details
    Given a race is selected
    When its detail view opens
    Then authoritative traits, speed, languages, and bonuses are shown

  @US-045 @proposed
  Scenario: View class details
    Given a class is selected
    When its detail view opens
    Then authoritative proficiencies, hit-die, and level-one features are shown
    # Proposed from the unnumbered GitHub class-detail issue #27.

  @US-046
  Scenario: Select the app language
    Given English and Spanish resources are bundled
    When the user selects a language
    Then navigation, validation, and SRD-facing copy use that locale

  @US-047
  Scenario: Localize the character experience
    Given the user has selected English or Spanish
    When any supported screen is used
    Then user-facing strings and format conventions are localized consistently

  @US-048
  Scenario: Convert and persist coin balances
    Given the user enters nonnegative whole cp, sp, ep, gp, or pp counts
    When conversion is applied
    Then SRD-equivalent value is shown in gp and the character balance is persisted
    And selected equipment remains unchanged

  @US-049
  Scenario: Expose accessible controls
    Given VoiceOver is enabled
    When the user navigates the supported journeys
    Then controls expose stable identifiers, labels, values, and actions

  @US-050
  Scenario: Protect sensitive text from keyboard caching
    Given a field is classified as sensitive by the accepted security policy
    When the field is edited
    Then keyboard caching is disabled for that field
    # Applicability for fictional character data remains an explicit decision.

  @US-051
  Scenario: Avoid sensitive logging
    Given the app encounters an error
    When diagnostics are emitted
    Then credentials, tokens, personal data, and full character payloads are not logged

  @US-052 @proposed
  Scenario: Apply race traits at level one
    Given a level-one race is selected
    When the character is recalculated
    Then every level-one trait and bonus from both SRD PDFs is represented or explicitly unsupported

  @US-053 @proposed
  Scenario: Apply class level-one features
    Given a level-one class is selected
    When the character is recalculated
    Then every level-one class feature from both SRD PDFs is represented or explicitly unsupported

  @US-054 @proposed
  Scenario: Apply background proficiencies and starting equipment
    Given a background is selected
    When the character is reviewed
    Then its authoritative skills, tools, languages, and equipment choices are represented

  @US-055 @proposed
  Scenario: Select and validate level-one spells
    Given a spellcasting class is selected
    When the user chooses spells
    Then only permitted level-zero and level-one spells and class choices from the SRD are offered

  @US-056 @proposed
  Scenario: Explain rules provenance in the catalogue
    Given a rule or localized entry is displayed
    When the user requests provenance
    Then the app can identify the English or Spanish SRD source and page/section reference

  @US-057 @proposed
  Scenario: Validate the complete level-one review
    Given all required choices are present
    When the user opens review
    Then missing choices and rule conflicts are identified before completion

  @US-058
  Scenario: Format source code consistently
    Given the repository quality command is run
    When formatting is checked
    Then the configured formatter reports deterministic, reviewable results without rewriting unrelated files

  @US-059
  Scenario: Detect dead code
    Given the repository is analyzed
    When dead-code detection runs
    Then findings identify unused production symbols separately from intentional public APIs

  @US-060
  Scenario: Analyze dependencies
    Given the source tree is analyzed
    When dependency checks run
    Then forbidden UI-to-domain or feature-to-feature dependencies are reported

  @US-061
  Scenario: Measure quality metrics
    Given unit coverage and complexity reports come from the same run
    When quality metrics are calculated
    Then method-level coverage, complexity, and CRAP are reported without substituting file metrics

  @US-062
  Scenario: Keep test tooling consistent
    Given unit, UI, and quality suites exist
    When the configured test command runs
    Then test scope, result paths, and failure status are unambiguous

  @US-063
  Scenario: Enforce architecture boundaries
    Given production source is analyzed
    When architecture tests run
    Then violations of the documented layer and framework boundaries fail the check

  @US-064
  Scenario: Validate changes in GitHub Actions
    Given a pull request changes application or quality files
    When CI runs
    Then formatting, architecture, unit, and applicable quality checks publish artifacts and an accurate status
