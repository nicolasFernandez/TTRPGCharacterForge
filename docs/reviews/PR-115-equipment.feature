# Source: https://github.com/nicolasFernandez/TTRPGCharacterForge/pull/115#pullrequestreview-5432038382
# Review comment: 4038268257. Scope: current bilingual seed catalog, no quantities or SRD expansion.
@US-PR115-EQUIPMENT
Feature: Complete a character with valid starting equipment
  Background:
    Given all non-equipment character choices are valid
    And the character has the required background equipment

  @AC-PR115-EQ-01 @SC-PR115-EQ-01
  Scenario Outline: An armor choice requires exactly one alternative
    Given a fighter without positive starting wealth
    And martial weapon and shield are selected
    When the character has selected <armor>
    Then completion is <result>
    Examples:
      | armor                           | result   |
      | chain mail                      | accepted |
      | leather armor                   | accepted |
      | chain mail and leather armor    | rejected |
      | no armor                        | rejected |

  @AC-PR115-EQ-02 @SC-PR115-EQ-02
  Scenario Outline: A bundle requires all its equipment
    Given a <class> without positive starting wealth
    And all other equipment groups have exactly one complete option selected
    When the character has selected <bundle>
    Then completion is <result>
    Examples:
      | class   | bundle                    | result   |
      | fighter | martial weapon and shield | accepted |
      | fighter | martial weapon only       | rejected |
      | fighter | shield only               | rejected |
      | paladin | martial weapon and shield | accepted |
      | paladin | martial weapon only       | rejected |
      | paladin | shield only               | rejected |

  @AC-PR115-EQ-03 @SC-PR115-EQ-03
  Scenario: Other seed alternatives and mandatory single items retain their meaning
    Given a barbarian without positive starting wealth
    When greataxe and explorer's pack are selected
    Then completion is accepted
    When martial weapon is also selected
    Then completion is rejected
    When martial weapon and explorer's pack are the only class equipment selected
    Then completion is accepted
    When explorer's pack is removed
    Then completion is rejected

  @AC-PR115-EQ-04 @SC-PR115-EQ-04
  Scenario: Positive wealth bypasses class choices but retains background requirements
    Given a fighter with positive starting wealth
    And no class equipment is selected
    When the character is completed
    Then completion is accepted
    When required background equipment is removed
    Then completion is rejected

  @AC-PR115-EQ-05 @SC-PR115-EQ-05
  Scenario Outline: Valid equipment survives offline save and relaunch in either language
    Given the app is offline in <language>
    And a fighter has chain mail, martial weapon, shield and required background equipment
    And no positive starting wealth
    When the character is saved and the app is relaunched
    Then the same equipment selections remain visible
    And completion is accepted
    Examples:
      | language |
      | English  |
      | Spanish  |

  @AC-PR115-EQ-06 @SC-PR115-EQ-06
  Scenario: Repeated equipment selections cannot complete a character
    Given a fighter has chain mail, martial weapon, shield and required background equipment
    And the saved equipment selections contain shield twice
    When the character is completed
    Then completion is rejected
