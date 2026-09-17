@US-048
Feature: Manage a character's money with the currency converter
  As a player
  I want to convert between cp, sp, ep, gp, and pp
  So that I can manage my character's money easily

  # Source: https://github.com/nicolasFernandez/TTRPGCharacterForge/issues/14
  #
  # Conservative MVP assumptions resolving details not specified by the issue:
  # - "Inventory" means a persisted five-denomination currency balance belonging
  #   to the selected character; applying a conversion replaces that balance and
  #   never changes the character's selected equipment.
  # - The converter accepts nonnegative whole coin counts in any or all fields.
  # - Values are summed exactly in copper pieces and normalized greedily in this
  #   order: pp, gp, ep, sp, cp. No value is rounded or discarded.
  # - Total gp is a reference display, not a floating-point calculation. It is
  #   the exact copper total divided by 100 and is localized for English/Spanish.
  # - A legacy character with starting wealth in gp and no currency balance is
  #   presented and persisted as that many gp on first currency save.

  Background:
    Given a player has selected a locally stored character
    And the character's selected equipment is recorded

  @AC-001 @AC-002 @AC-003 @SC-001
  Scenario: Normalize a mixed balance using every SRD denomination
    Given the currency converter is open
    When the player enters 105 cp, 11 sp, 3 ep, 12 gp, and 2 pp
    Then the exact total is 3565 cp
    And the normalized balance is 3 pp, 5 gp, 1 ep, 1 sp, and 5 cp

  @AC-002 @AC-003 @SC-002
  Scenario Outline: Convert each denomination in both higher and lower directions
    Given the currency converter is open
    When the player enters <amount> <input>
    Then the exact total is <copper_total> cp
    And the normalized balance is <normalized>

    Examples:
      | amount | input | copper_total | normalized                         |
      | 10     | cp    | 10           | 0 pp, 0 gp, 0 ep, 1 sp, and 0 cp  |
      | 10     | sp    | 100          | 0 pp, 1 gp, 0 ep, 0 sp, and 0 cp  |
      | 2      | ep    | 100          | 0 pp, 1 gp, 0 ep, 0 sp, and 0 cp  |
      | 10     | gp    | 1000         | 1 pp, 0 gp, 0 ep, 0 sp, and 0 cp  |
      | 1      | pp    | 1000         | 1 pp, 0 gp, 0 ep, 0 sp, and 0 cp  |
      | 1      | gp    | 100          | 0 pp, 1 gp, 0 ep, 0 sp, and 0 cp  |
      | 1      | sp    | 10           | 0 pp, 0 gp, 0 ep, 1 sp, and 0 cp  |
      | 1      | cp    | 1            | 0 pp, 0 gp, 0 ep, 0 sp, and 1 cp  |

  @AC-004 @SC-003
  Scenario: Apply and persist the normalized balance without changing equipment
    Given the character has 1 pp, 2 gp, 0 ep, 3 sp, and 4 cp
    When the player changes the balance to 0 pp, 0 gp, 0 ep, 0 sp, and 250 cp
    And the player applies the conversion to the character
    Then the character's persisted balance is 0 pp, 2 gp, 1 ep, 0 sp, and 0 cp
    And the character's selected equipment is unchanged
    When the player closes and relaunches the app offline
    And the player opens the same character's currency converter
    Then the balance is 0 pp, 2 gp, 1 ep, 0 sp, and 0 cp

  @AC-004 @SC-004
  Scenario: Migrate legacy gp wealth into the currency balance
    Given a legacy character has starting wealth of 37 gp
    And the character has no persisted five-denomination currency balance
    When the player opens the character's currency converter
    Then the displayed balance is 0 pp, 37 gp, 0 ep, 0 sp, and 0 cp
    When the player applies the conversion to the character
    And the player closes and relaunches the app offline
    Then the character's persisted balance is 3 pp, 7 gp, 0 ep, 0 sp, and 0 cp
    And the character's selected equipment is unchanged

  @AC-005 @SC-005
  Scenario Outline: Display the exact total value in gp for reference
    Given the currency converter is open in <locale>
    When the player enters 1 cp, 1 sp, 1 ep, 1 gp, and 1 pp
    Then the total gp reference displays <total_gp>

    Examples:
      | locale        | total_gp |
      | English       | 11.61 gp |
      | Spanish       | 11,61 gp |

  @AC-006 @SC-006
  Scenario Outline: Reject invalid coin input without changing the saved balance
    Given the character's saved balance is 0 pp, 5 gp, 0 ep, 0 sp, and 0 cp
    And the currency converter is open
    When the player enters <invalid_value> in the <denomination> field
    And the player attempts to apply the conversion
    Then a localized validation message explains that coin counts must be nonnegative whole numbers
    And the character's saved balance remains 0 pp, 5 gp, 0 ep, 0 sp, and 0 cp
    And the character's selected equipment is unchanged

    Examples:
      | invalid_value | denomination |
      | -1            | cp           |
      | 1.5           | gp           |
      | coins         | pp           |

  @AC-006 @SC-007
  Scenario: Reject a balance whose exact copper total would overflow
    Given the character's saved balance is 0 pp, 5 gp, 0 ep, 0 sp, and 0 cp
    And the currency converter is open
    When the player enters a syntactically valid whole coin count whose conversion cannot be represented safely
    And the player attempts to apply the conversion
    Then a localized message explains that the amount is too large
    And no partial conversion result is displayed as saved
    And the character's saved balance remains 0 pp, 5 gp, 0 ep, 0 sp, and 0 cp
    And the character's selected equipment is unchanged

  @AC-007 @SC-008
  Scenario: Convert and save while offline
    Given the device has no network connection
    And the currency converter is open
    When the player enters 25 sp
    And the player applies the conversion to the character
    Then the character's persisted balance is 0 pp, 2 gp, 1 ep, 0 sp, and 0 cp
    And no network connection is requested

  @AC-008 @SC-009
  Scenario Outline: Use the complete converter in each supported language and device class
    Given the app is running on <device> in <locale>
    When the player opens a character's currency converter
    Then the title, denomination labels, total-gp reference, validation text, and apply action are localized in <locale>
    And all five coin inputs and the apply action are visible and operable without clipped or overlapping content

    Examples:
      | device | locale  |
      | iPhone | English |
      | iPhone | Spanish |
      | iPad   | English |
      | iPad   | Spanish |
