import XCTest
import PDFKit
import UIKit
@testable import TTRPGCharacterForge

final class PR115DomainTests: XCTestCase {
    // UT-PR115-SKILLS: duplicate class or background IDs cannot complete a character.
    func testCompletionRejectsDuplicateSkillSelections() throws {
        let catalog = try BundledRulesRepository().catalog(locale: .english)
        var character = equipmentFixture()
        character.startingWealthGP = 10
        XCTAssertNoThrow(try CreateCharacterUseCase().validateForCompletion(character, catalog: catalog))
        for duplicate in ["athletics", "religion"] {
            var malformed = character
            malformed.selectedSkillIDs.append(duplicate)
            XCTAssertThrowsError(try CreateCharacterUseCase().validateForCompletion(malformed, catalog: catalog))
        }
    }

    func testStandardArrayReassignmentSwapsExistingOwner() throws {
        var character = CharacterDocument(
            baseAbilities: AbilityScoreSet(strength: 15, dexterity: 14, constitution: 13, intelligence: 12, wisdom: 10, charisma: 8),
            abilityMethod: .standardArray
        )
        try UpdateAbilityScoreUseCase().execute(character: &character, ability: .strength, score: 14, method: .standardArray)
        XCTAssertEqual(character.baseAbilities.strength, 14)
        XCTAssertEqual(character.baseAbilities.dexterity, 15)
        XCTAssertTrue(AbilityAssignmentService().validate(character.baseAbilities, method: .standardArray))
    }

    // UT-PR115-POINTBUY-27: assigning the final point permits the exact accepted budget.
    func testPointBuyAllowsExactlyTwentySevenPoints() throws {
        var character = CharacterDocument(
            name: "Point Buy Boundary",
            baseAbilities: AbilityScoreSet(strength: 15, dexterity: 15, constitution: 14, intelligence: 9, wisdom: 8, charisma: 8),
            abilityMethod: .pointBuy
        )
        let originalID = character.id
        let expected = AbilityScoreSet(strength: 15, dexterity: 15, constitution: 14, intelligence: 10, wisdom: 8, charisma: 8)

        try UpdateAbilityScoreUseCase().execute(character: &character, ability: .intelligence, score: 10, method: .pointBuy)

        XCTAssertEqual(character.baseAbilities, expected)
        XCTAssertEqual(character.abilityMethod, .pointBuy)
        XCTAssertEqual(character.id, originalID)
        XCTAssertEqual(character.name, "Point Buy Boundary")
        XCTAssertTrue(AbilityAssignmentService().validate(character.baseAbilities, method: .pointBuy))
    }

    func testPointBuyRejectsOverspendingWithoutChangingDocument() throws {
        var character = CharacterDocument(
            baseAbilities: AbilityScoreSet(strength: 15, dexterity: 15, constitution: 15, intelligence: 8, wisdom: 8, charisma: 8),
            abilityMethod: .pointBuy
        )
        let original = character
        XCTAssertThrowsError(try UpdateAbilityScoreUseCase().execute(character: &character, ability: .charisma, score: 9, method: .pointBuy))
        XCTAssertEqual(character, original)
    }

    func testSwitchingMethodAllowsIncrementalDraftAssignment() throws {
        var character = CharacterDocument(
            baseAbilities: AbilityScoreSet(strength: 18, dexterity: 18, constitution: 18, intelligence: 18, wisdom: 18, charisma: 18),
            abilityMethod: .rolled
        )
        for ability in AbilityID.allCases {
            try UpdateAbilityScoreUseCase().execute(character: &character, ability: ability, score: 8, method: .pointBuy)
        }
        XCTAssertEqual(character.baseAbilities, AbilityScoreSet(strength: 8, dexterity: 8, constitution: 8, intelligence: 8, wisdom: 8, charisma: 8))
        XCTAssertFalse(AbilityAssignmentService().validate(character.baseAbilities, method: .pointBuy))
    }

    func testCompletionRequiresBackgroundEquipmentEvenWithWealth() throws {
        let catalog = try BundledRulesRepository().catalog(locale: .english)
        var character = equipmentFixture()
        character.startingWealthGP = 10
        character.selectedEquipmentIDs = []
        XCTAssertThrowsError(try CreateCharacterUseCase().validateForCompletion(character, catalog: catalog))
        character.selectedEquipmentIDs = ["holy-symbol"]
        XCTAssertNoThrow(try CreateCharacterUseCase().validateForCompletion(character, catalog: catalog))
    }

    func testZeroWealthCannotReplaceClassEquipmentChoices() throws {
        let catalog = try BundledRulesRepository().catalog(locale: .english)
        var character = equipmentFixture()
        character.startingWealthGP = 0
        XCTAssertThrowsError(try CreateCharacterUseCase().validateForCompletion(character, catalog: catalog))
        character.currencyBalance = .zero
        XCTAssertThrowsError(try CreateCharacterUseCase().validateForCompletion(character, catalog: catalog))
        character.currencyBalance = CurrencyBalance(copper: -1, gold: 10)
        XCTAssertThrowsError(try CreateCharacterUseCase().validateForCompletion(character, catalog: catalog))
        character.currencyBalance = CurrencyBalance(copper: 1)
        XCTAssertNoThrow(try CreateCharacterUseCase().validateForCompletion(character, catalog: catalog))
    }

    func testHeavyArmorIgnoresNegativeDexterityWhileMediumArmorRetainsIt() throws {
        var catalog = try BundledRulesRepository().catalog(locale: .english)
        var character = equipmentFixture()
        character.baseAbilities.dexterity = 8
        let index = try XCTUnwrap(catalog.equipment.firstIndex { $0.id == "chain-mail" })
        catalog.equipment[index].dexterityCap = 0
        character.selectedEquipmentIDs = ["chain-mail"]
        XCTAssertEqual(try ComputeDerivedStatsUseCase().execute(character: character, catalog: catalog).armorClass, catalog.equipment[index].armorClass)
        catalog.equipment[index].dexterityCap = 2
        XCTAssertEqual(try ComputeDerivedStatsUseCase().execute(character: character, catalog: catalog).armorClass, try XCTUnwrap(catalog.equipment[index].armorClass) - 1)
    }

    func testCatalogRejectsUnknownSpellSchoolAndEmptyClassList() throws {
        var catalog = try BundledRulesRepository().catalog(locale: .english)
        catalog.spells[0].school = "unknown-school"
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))
        catalog = try BundledRulesRepository().catalog(locale: .english)
        catalog.spells[0].classIDs = []
        XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))
    }

    func testSameNamedTokenExportsUseDistinctFiles() throws {
        let exporter = GenerateVTTTokenUseCase(renderer: RecordingTokenRenderer())
        let first = try exporter.execute(imageData: Data(), filename: "same")
        let second = try exporter.execute(imageData: Data(), filename: "same")
        defer {
            try? FileManager.default.removeItem(at: first)
            try? FileManager.default.removeItem(at: second)
        }
        XCTAssertNotEqual(first, second)
        XCTAssertTrue(FileManager.default.fileExists(atPath: first.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: second.path))
    }

    func testPDFUsesEachBundledLocaleTemplateAndContainsCharacterValues() throws {
        for locale in [RulesLocale.english, .spanish] {
            let catalog = try BundledRulesRepository().catalog(locale: locale)
            let character = equipmentFixture()
            let url = try CharacterSheetPDFExporter().export(character, catalog: catalog)
            defer { try? FileManager.default.removeItem(at: url) }
            XCTAssertTrue(url.lastPathComponent.hasPrefix(locale == .english ? "2014_EN_Character_Sheet" : "2014_ES_Character_Sheet"))
            let document = try XCTUnwrap(PDFDocument(url: url))
            XCTAssertEqual(document.pageCount, 3)
            let pdfAttachment = XCTAttachment(data: try Data(contentsOf: url), uniformTypeIdentifier: "com.adobe.pdf")
            pdfAttachment.name = "filled-sheet-\(locale.rawValue)"
            pdfAttachment.lifetime = .keepAlways
            add(pdfAttachment)
            for index in 0..<document.pageCount {
                let page = try XCTUnwrap(document.page(at: index))
                let bounds = page.bounds(for: .mediaBox)
                let renderer = UIGraphicsImageRenderer(size: bounds.size)
                let image = renderer.image { rendererContext in
                    UIColor.white.setFill()
                    rendererContext.fill(bounds)
                    rendererContext.cgContext.translateBy(x: 0, y: bounds.height)
                    rendererContext.cgContext.scaleBy(x: 1, y: -1)
                    page.draw(with: .mediaBox, to: rendererContext.cgContext)
                }
                let attachment = XCTAttachment(
                    data: try XCTUnwrap(image.pngData()), uniformTypeIdentifier: "public.png"
                )
                attachment.name = "filled-sheet-\(locale.rawValue)-page-\(index + 1)"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
            XCTAssertTrue(document.string?.contains(character.name) == true)
            XCTAssertTrue(document.string?.contains("15") == true)
        }
    }

    private func equipmentFixture() -> CharacterDocument {
        CharacterDocument(
            name: "Equipment Review",
            raceID: "dragonborn",
            classID: "barbarian",
            backgroundID: "acolyte",
            baseAbilities: AbilityScoreSet(strength: 15, dexterity: 14, constitution: 13, intelligence: 12, wisdom: 10, charisma: 8),
            abilityMethod: .standardArray,
            selectedSkillIDs: ["insight", "religion", "athletics", "survival"],
            selectedLanguageIDs: ["common", "draconic", "dwarvish", "elvish"],
            selectedEquipmentIDs: ["holy-symbol"]
        )
    }

    func testTokenUseCaseDelegatesCropAndWritesPNGBytes() throws {
        let renderer = RecordingTokenRenderer()
        let exporter = GenerateVTTTokenUseCase(renderer: renderer)
        let crop = NormalizedCrop.fullImage
        let url = try exporter.execute(imageData: Data([1, 2]), filename: UUID().uuidString, crop: crop)
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertEqual(renderer.receivedData, Data([1, 2]))
        XCTAssertEqual(renderer.receivedCrop, crop)
        XCTAssertEqual(try Data(contentsOf: url), Data([3, 4]))
        XCTAssertEqual(url.pathExtension, "png")
    }
}

private final class RecordingTokenRenderer: TokenRendering {
    var receivedData: Data?
    var receivedCrop: NormalizedCrop?
    func render(imageData: Data, crop: NormalizedCrop) throws -> Data {
        receivedData = imageData
        receivedCrop = crop
        return Data([3, 4])
    }
}

// Equipment regression cases share the existing character fixture.
extension PR115DomainTests {
    // UT-PR115-EQ-01 / SC-PR115-EQ-01: one armor alternative, never both or neither.
    func testFighterRequiresExactlyOneArmorAlternative() throws {
        for locale in [RulesLocale.english, .spanish] {
            let catalog = try BundledRulesRepository().catalog(locale: locale)
            for armor in [["chain-mail"], ["leather-armor"], ["chain-mail", "leather-armor"], []] {
                var character = equipmentFixture()
                character.classID = "fighter"
                character.selectedEquipmentIDs += armor + ["martial-weapon", "shield"]
                if armor.count == 1 {
                    XCTAssertNoThrow(
                        try CreateCharacterUseCase().validateForCompletion(character, catalog: catalog)
                    )
                } else {
                    XCTAssertThrowsError(
                        try CreateCharacterUseCase().validateForCompletion(character, catalog: catalog)
                    )
                }
            }
        }
    }

    // UT-PR115-EQ-02 / SC-PR115-EQ-02: every member of fighter/paladin bundles is required.
    func testWeaponShieldBundleRequiresBothItems() throws {
        let catalog = try BundledRulesRepository().catalog(locale: .english)
        for classID in ["fighter", "paladin"] {
            for bundle in [["martial-weapon", "shield"], ["martial-weapon"], ["shield"], []] {
                var character = equipmentFixture()
                character.classID = classID
                if classID == "paladin" {
                    character.selectedSkillIDs = ["insight", "religion", "athletics", "intimidation"]
                }
                character.selectedEquipmentIDs += [classID == "fighter" ? "chain-mail" : "javelin"] + bundle
                if bundle.count == 2 {
                    XCTAssertNoThrow(
                        try CreateCharacterUseCase().validateForCompletion(character, catalog: catalog)
                    )
                } else {
                    XCTAssertThrowsError(
                        try CreateCharacterUseCase().validateForCompletion(character, catalog: catalog)
                    )
                }
            }
        }
    }

    // UT-PR115-EQ-03 / SC-PR115-EQ-03: single item alternatives and mandatory packs.
    func testBarbarianAlternativesAndRequiredPack() throws {
        let catalog = try BundledRulesRepository().catalog(locale: .english)
        for weapon in ["greataxe", "martial-weapon"] {
            var character = equipmentFixture()
            character.selectedEquipmentIDs += [weapon, "explorers-pack"]
            XCTAssertNoThrow(
                try CreateCharacterUseCase().validateForCompletion(character, catalog: catalog)
            )
            character.selectedEquipmentIDs.removeAll { $0 == "explorers-pack" }
            XCTAssertThrowsError(
                try CreateCharacterUseCase().validateForCompletion(character, catalog: catalog)
            )
        }
        var mixed = equipmentFixture()
        mixed.selectedEquipmentIDs += ["greataxe", "martial-weapon", "explorers-pack"]
        XCTAssertThrowsError(try CreateCharacterUseCase().validateForCompletion(mixed, catalog: catalog))
    }

    // UT-PR115-EQ-04 / SC-PR115-EQ-04: class choice bypass retains background and allowed-ID checks.
    func testFighterWealthPreservesBackgroundAndAllowedEquipment() throws {
        let catalog = try BundledRulesRepository().catalog(locale: .english)
        var character = equipmentFixture()
        character.classID = "fighter"
        character.startingWealthGP = 1
        XCTAssertNoThrow(
            try CreateCharacterUseCase().validateForCompletion(character, catalog: catalog)
        )
        character.selectedEquipmentIDs = []
        XCTAssertThrowsError(
            try CreateCharacterUseCase().validateForCompletion(character, catalog: catalog)
        )
        character.selectedEquipmentIDs = ["holy-symbol", "unknown-equipment"]
        XCTAssertThrowsError(
            try CreateCharacterUseCase().validateForCompletion(character, catalog: catalog)
        )
    }

    // UT-PR115-EQ-05 / SC-PR115-EQ-05: locale parity and unchanged document equipment encoding.
    // Save/relaunch through the UI remains a separate QA check.
    func testEquipmentCatalogParityAndDocumentRoundTrip() throws {
        let english = try BundledRulesRepository().catalog(locale: .english)
        let spanish = try BundledRulesRepository().catalog(locale: .spanish)
        XCTAssertEqual(english.schemaVersion, 2)
        XCTAssertEqual(spanish.schemaVersion, 2)
        XCTAssertEqual(english.classes.map(\.id), spanish.classes.map(\.id))
        XCTAssertEqual(english.classes.map(\.equipmentChoiceGroups), spanish.classes.map(\.equipmentChoiceGroups))
        for catalog in [english, spanish] {
            try RulesCatalogValidator().validate(catalog)
            var character = equipmentFixture()
            character.classID = "fighter"
            character.selectedEquipmentIDs += ["chain-mail", "martial-weapon", "shield"]
            let restored = try JSONDecoder().decode(CharacterDocument.self, from: JSONEncoder().encode(character))
            XCTAssertEqual(restored, character)
            XCTAssertNoThrow(try CreateCharacterUseCase().validateForCompletion(restored, catalog: catalog))
        }
    }

    // UT-PR115-EQ-06 / SC-PR115-EQ-06: duplicate equipment IDs never complete, including with wealth.
    func testDuplicateEquipmentRejectedWithAndWithoutWealth() throws {
        let catalog = try BundledRulesRepository().catalog(locale: .english)
        for wealth in [0, 1] {
            var character = equipmentFixture()
            character.classID = "fighter"
            character.startingWealthGP = wealth
            character.selectedEquipmentIDs += ["chain-mail", "martial-weapon", "shield", "shield"]
            XCTAssertThrowsError(
                try CreateCharacterUseCase().validateForCompletion(character, catalog: catalog)
            )
        }
    }

    func testCatalogRejectsMalformedEquipmentGroups() throws {
        let malformedOptions: [[[String]]] = [
            [], [[]], [["unknown-equipment"]], [["shield", "shield"]], [["shield"], ["shield"]],
            [["shield", "martial-weapon"], ["martial-weapon", "shield"]]
        ]
        for options in malformedOptions {
            var catalog = try BundledRulesRepository().catalog(locale: .english)
            catalog.classes[0].equipmentChoiceGroups = [EquipmentChoiceGroup(options: options)]
            XCTAssertThrowsError(try RulesCatalogValidator().validate(catalog))
        }
    }
}
