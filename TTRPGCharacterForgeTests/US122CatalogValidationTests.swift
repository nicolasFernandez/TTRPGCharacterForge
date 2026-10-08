import XCTest
@testable import TTRPGCharacterForge

final class US122CatalogValidationTests: XCTestCase {
    // UT-122-01 / CAT-122-01 / AC-122-01 / SC-122-01
    func testCompleteBundledCatalogsDecodeAndMeetInventoryInvariants() throws {
        for locale in [RulesLocale.english, .spanish] {
            let catalog = try BundledRulesRepository().catalog(locale: locale)

            XCTAssertEqual(catalog.schemaVersion, RulesCatalog.supportedSchemaVersion)
            XCTAssertEqual(catalog.races.count, 9)
            XCTAssertEqual(catalog.classes.count, 12)
            XCTAssertEqual(catalog.backgrounds.count, 1)
            XCTAssertEqual(catalog.skills.count, 18)
            XCTAssertEqual(catalog.languages.count, 16)
            XCTAssertEqual(catalog.equipment.count, 27)
            XCTAssertEqual(catalog.spells.count, 6)
            XCTAssertEqual(catalogEntryCount(catalog), 89)
            XCTAssertNoThrow(try RulesCatalogValidator().validate(catalog))
        }
    }

    // UT-122-02 / CAT-122-01 / AC-122-01 / SC-122-01
    func testCatalogRejectsBlankStableIDsAndRequiredLocalizedText() throws {
        var catalog = try BundledRulesRepository().catalog(locale: .english)
        catalog.races[0].id = " \n"
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))

        catalog = try BundledRulesRepository().catalog(locale: .english)
        catalog.classes[0].name = "\t"
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))

        catalog = try BundledRulesRepository().catalog(locale: .english)
        catalog.backgrounds[0].description = " "
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))

        catalog = try BundledRulesRepository().catalog(locale: .english)
        let dwarfIndex = try XCTUnwrap(catalog.races.firstIndex { $0.id == "dwarf" })
        catalog.races[dwarfIndex].subraces[0].name = ""
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))

        catalog = try BundledRulesRepository().catalog(locale: .english)
        catalog.spells[0].components = ""
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))
    }

    // UT-122-07 / CAT-122-05 / AC-122-06 / SC-122-06
    func testCatalogRejectsUnsupportedSchemaVersion() throws {
        var catalog = try BundledRulesRepository().catalog(locale: .english)
        catalog.schemaVersion = 999

        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))
    }

    // UT-122-03 / CAT-122-04 / CAT-122-05 / AC-122-04 / SC-122-04
    func testBundledCatalogsHavePairedIDsCompatibleMechanicsAndSameLocaleReferences() throws {
        let english = try BundledRulesRepository().catalog(locale: .english)
        let spanish = try BundledRulesRepository().catalog(locale: .spanish)

        XCTAssertNoThrow(try BilingualRulesCatalogValidator().validate(english: english, spanish: spanish))
    }

    // UT-122-04 / CAT-122-04 / AC-122-04 / SC-122-04
    func testBilingualValidationRejectsMissingPairAndMechanicalMismatch() throws {
        let english = try BundledRulesRepository().catalog(locale: .english)
        var spanish = try BundledRulesRepository().catalog(locale: .spanish)
        spanish.skills.removeLast()
        XCTAssertThrowsError(try BilingualRulesCatalogValidator().validate(english: english, spanish: spanish))

        spanish = try BundledRulesRepository().catalog(locale: .spanish)
        spanish.races[0].speed += 5
        XCTAssertThrowsError(try BilingualRulesCatalogValidator().validate(english: english, spanish: spanish))

        spanish = try BundledRulesRepository().catalog(locale: .spanish)
        spanish.equipment[0].costGP += 1
        XCTAssertThrowsError(try BilingualRulesCatalogValidator().validate(english: english, spanish: spanish))
    }

    // UT-122-05 / CAT-122-04 / AC-122-04 / SC-122-04
    func testCatalogRejectsBlankOrDanglingSupportedReferences() throws {
        var catalog = try BundledRulesRepository().catalog(locale: .english)
        catalog.classes[0].availableSkillIDs[0] = " "
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))

        catalog = try BundledRulesRepository().catalog(locale: .english)
        catalog.backgrounds[0].grantedEquipmentIDs[0] = "missing-item"
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))

        catalog = try BundledRulesRepository().catalog(locale: .english)
        catalog.spells[0].classIDs[0] = "missing-class"
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))
    }

    // UT-122-06 / CAT-122-04 / AC-122-04 / AC-122-05 / SC-122-04 / SC-122-05
    func testFeatureIDsArePairedButNotResolvedAgainstAnInventedRegistry() throws {
        var english = try BundledRulesRepository().catalog(locale: .english)
        var spanish = try BundledRulesRepository().catalog(locale: .spanish)
        english.races[0].featureIDs = ["unregistered-feature"]
        spanish.races[0].featureIDs = ["unregistered-feature"]

        XCTAssertNoThrow(try RulesCatalogValidator().validate(english))
        XCTAssertNoThrow(try RulesCatalogValidator().validate(spanish))
        XCTAssertNoThrow(try BilingualRulesCatalogValidator().validate(english: english, spanish: spanish))

        spanish.races[0].featureIDs = ["different-feature"]
        XCTAssertThrowsError(try BilingualRulesCatalogValidator().validate(english: english, spanish: spanish))
    }

    // UT-122-08 / CAT-122-04 / AC-122-04 / SC-122-04
    func testBilingualValidationRejectsDamageTypeAndModifierMismatch() throws {
        let english = try BundledRulesRepository().catalog(locale: .english)
        var spanish = try BundledRulesRepository().catalog(locale: .spanish)
        let index = try XCTUnwrap(spanish.equipment.firstIndex { $0.id == "greataxe" })
        spanish.equipment[index].damageType = .piercing
        XCTAssertThrowsError(try BilingualRulesCatalogValidator().validate(english: english, spanish: spanish))

        spanish = try BundledRulesRepository().catalog(locale: .spanish)
        let modifierIndex = try XCTUnwrap(spanish.equipment.firstIndex { $0.id == "greataxe" })
        spanish.equipment[modifierIndex].damageDice?.modifier = 1
        XCTAssertThrowsError(try BilingualRulesCatalogValidator().validate(english: english, spanish: spanish))
    }

    // UT-122-09 / CAT-122-04 / AC-122-04 / SC-122-04
    func testBilingualValidationRejectsSpellComponentLoss() throws {
        let english = try BundledRulesRepository().catalog(locale: .english)
        var spanish = try BundledRulesRepository().catalog(locale: .spanish)
        let index = try XCTUnwrap(spanish.spells.firstIndex { $0.id == "acid-splash" })
        spanish.spells[index].componentSet.remove(.somatic)

        XCTAssertThrowsError(try BilingualRulesCatalogValidator().validate(english: english, spanish: spanish))
    }

    // UT-122-10 / CAT-122-04 / AC-122-04 / SC-122-04
    func testBilingualValidationRejectsHigherLevelPresenceMismatch() throws {
        let english = try BundledRulesRepository().catalog(locale: .english)
        var spanish = try BundledRulesRepository().catalog(locale: .spanish)
        let index = try XCTUnwrap(spanish.spells.firstIndex { $0.id == "cure-wounds" })
        spanish.spells[index].higherLevels = nil
        spanish.spells[index].hasHigherLevels = false

        XCTAssertThrowsError(try BilingualRulesCatalogValidator().validate(english: english, spanish: spanish))
    }

    // UT-122-11 / CAT-122-04 / AC-122-04 / SC-122-04
    func testBilingualValidationRejectsNumericAndCategoryRangeDrift() throws {
        let english = try BundledRulesRepository().catalog(locale: .english)
        var spanish = try BundledRulesRepository().catalog(locale: .spanish)
        let index = try XCTUnwrap(spanish.spells.firstIndex { $0.id == "acid-splash" })
        spanish.spells[index].rangeMechanic.distanceFeet = 65
        XCTAssertThrowsError(try BilingualRulesCatalogValidator().validate(english: english, spanish: spanish))

        spanish = try BundledRulesRepository().catalog(locale: .spanish)
        let categoryIndex = try XCTUnwrap(spanish.spells.firstIndex { $0.id == "acid-splash" })
        spanish.spells[categoryIndex].rangeMechanic = SpellRange(kind: .touch, distanceFeet: nil)
        XCTAssertThrowsError(try BilingualRulesCatalogValidator().validate(english: english, spanish: spanish))
    }

    // UT-122-12 / CAT-122-04 / AC-122-04 / SC-122-04
    func testBilingualValidationRejectsDurationAndCastingTimeDrift() throws {
        let english = try BundledRulesRepository().catalog(locale: .english)
        var spanish = try BundledRulesRepository().catalog(locale: .spanish)
        let durationIndex = try XCTUnwrap(spanish.spells.firstIndex { $0.id == "light" })
        spanish.spells[durationIndex].durationMechanic.amount = 2
        XCTAssertThrowsError(try BilingualRulesCatalogValidator().validate(english: english, spanish: spanish))

        spanish = try BundledRulesRepository().catalog(locale: .spanish)
        let castingIndex = try XCTUnwrap(spanish.spells.firstIndex { $0.id == "light" })
        spanish.spells[castingIndex].castingTimeMechanic.amount = 2
        XCTAssertThrowsError(try BilingualRulesCatalogValidator().validate(english: english, spanish: spanish))
    }

    // UT-122-13 / CAT-122-05 / AC-122-06 / SC-122-06
    func testCatalogRejectsIncompleteOrInvalidDamageMechanics() throws {
        var catalog = try BundledRulesRepository().catalog(locale: .english)
        let typeIndex = try XCTUnwrap(catalog.equipment.firstIndex { $0.id == "greataxe" })
        catalog.equipment[typeIndex].damageType = nil
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))

        catalog = try BundledRulesRepository().catalog(locale: .english)
        let canonicalIndex = try XCTUnwrap(catalog.equipment.firstIndex { $0.id == "greataxe" })
        catalog.equipment[canonicalIndex].damageDice = nil
        catalog.equipment[canonicalIndex].damageType = nil
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))

        catalog = try BundledRulesRepository().catalog(locale: .english)
        let displayIndex = try XCTUnwrap(catalog.equipment.firstIndex { $0.id == "greataxe" })
        catalog.equipment[displayIndex].damage = nil
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))

        catalog = try BundledRulesRepository().catalog(locale: .english)
        let diceIndex = try XCTUnwrap(catalog.equipment.firstIndex { $0.id == "greataxe" })
        catalog.equipment[diceIndex].damageDice?.numberOfDice = 0
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))

        catalog = try BundledRulesRepository().catalog(locale: .english)
        let sidesIndex = try XCTUnwrap(catalog.equipment.firstIndex { $0.id == "greataxe" })
        catalog.equipment[sidesIndex].damageDice?.sides = 0
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))
    }

    // UT-122-14 / CAT-122-05 / AC-122-06 / SC-122-06
    func testCatalogRejectsInvalidSpellRangeShapes() throws {
        var catalog = try BundledRulesRepository().catalog(locale: .english)
        let distanceIndex = try XCTUnwrap(catalog.spells.firstIndex { $0.id == "acid-splash" })
        catalog.spells[distanceIndex].rangeMechanic.distanceFeet = nil
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))

        catalog = try BundledRulesRepository().catalog(locale: .english)
        let touchIndex = try XCTUnwrap(catalog.spells.firstIndex { $0.id == "light" })
        catalog.spells[touchIndex].rangeMechanic.distanceFeet = 5
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))
    }

    // UT-122-15 / CAT-122-05 / AC-122-06 / SC-122-06
    func testCatalogRejectsInvalidSpellDurationShapes() throws {
        var catalog = try BundledRulesRepository().catalog(locale: .english)
        let timedIndex = try XCTUnwrap(catalog.spells.firstIndex { $0.id == "light" })
        catalog.spells[timedIndex].durationMechanic.unit = nil
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))

        catalog = try BundledRulesRepository().catalog(locale: .english)
        let instantIndex = try XCTUnwrap(catalog.spells.firstIndex { $0.id == "acid-splash" })
        catalog.spells[instantIndex].durationMechanic.amount = 1
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))
    }

    // UT-122-16 / CAT-122-05 / AC-122-06 / SC-122-06
    func testCatalogRejectsEmptyComponentsAndHigherLevelPresenceInconsistency() throws {
        var catalog = try BundledRulesRepository().catalog(locale: .english)
        let componentIndex = try XCTUnwrap(catalog.spells.firstIndex { $0.id == "acid-splash" })
        catalog.spells[componentIndex].componentSet = []
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))

        catalog = try BundledRulesRepository().catalog(locale: .english)
        let higherLevelIndex = try XCTUnwrap(catalog.spells.firstIndex { $0.id == "cure-wounds" })
        catalog.spells[higherLevelIndex].hasHigherLevels = false
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))
    }

    private func catalogEntryCount(_ catalog: RulesCatalog) -> Int {
        catalog.races.count + catalog.classes.count + catalog.backgrounds.count + catalog.skills.count
            + catalog.languages.count + catalog.equipment.count + catalog.spells.count
    }
}
