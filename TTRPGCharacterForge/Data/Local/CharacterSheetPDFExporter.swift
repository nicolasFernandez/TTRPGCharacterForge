import Foundation
import UIKit
import PDFKit

/// Fills the bundled bilingual 2014 sheet. English widgets also provide the
/// field geometry for the flattened Spanish edition of the same sheet.
struct CharacterSheetPDFExporter: PdfExporter {
    private let bundle: Bundle
    init(bundle: Bundle = .main) { self.bundle = bundle }

    func export(_ character: CharacterDocument, catalog: RulesCatalog) throws -> URL {
        let stats = try ComputeDerivedStatsUseCase().execute(character: character, catalog: catalog)
        let name = catalog.locale == RulesLocale.spanish.rawValue
            ? "2014_ES_Character_Sheet" : "2014_EN_Character_Sheet"
        let document = try template(name)
        let geometry = try template("2014_EN_Character_Sheet")
        let values = fieldValues(character, catalog: catalog, stats: stats)
        fill(document, geometry: geometry, values: values)
        let output = FileManager.default.temporaryDirectory.appendingPathComponent("\(name)-\(UUID().uuidString).pdf")
        try render(document, geometry: geometry, character: character, output: output)
        return output
    }

    private func fill(_ document: PDFDocument, geometry: PDFDocument, values: [String: String]) {
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index), let source = geometry.page(at: index) else { continue }
            fillPage(page, source: source, document: document, values: values)
        }
    }

    private func fillPage(_ page: PDFPage, source: PDFPage, document: PDFDocument, values: [String: String]) {
        for field in source.annotations {
            guard let key = field.fieldName?.trimmingCharacters(in: .whitespaces),
                  let value = values[key] else { continue }
            if let widget = page.annotations.first(where: {
                $0.fieldName?.trimmingCharacters(in: .whitespaces) == key
            }) {
                widget.widgetStringValue = value
                widget.font = UIFont.systemFont(ofSize: 9)
                widget.fontColor = .black
            } else {
                addOverlay(value, key: key, field: field, page: page, document: document)
            }
        }
    }

    private func addOverlay(
        _ value: String,
        key: String,
        field: PDFAnnotation,
        page: PDFPage,
        document: PDFDocument
    ) {
        guard let source = field.page else { return }
        let sourceBounds = source.bounds(for: .mediaBox)
        let targetBounds = page.bounds(for: .mediaBox)
        var rect = CGRect(
            x: field.bounds.minX * targetBounds.width / sourceBounds.width,
            y: field.bounds.minY * targetBounds.height / sourceBounds.height,
            width: field.bounds.width * targetBounds.width / sourceBounds.width,
            height: field.bounds.height * targetBounds.height / sourceBounds.height
        )
        if let label = spanishSkillLabels[key],
           let selection = document.findString(label, withOptions: .caseInsensitive).first,
           selection.pages.contains(page) {
            let labelBounds = selection.bounds(for: page)
            rect = CGRect(x: labelBounds.minX - 19, y: labelBounds.minY, width: 15, height: 10)
        }
        let annotation = PDFAnnotation(bounds: rect, forType: .freeText, withProperties: nil)
        annotation.contents = value
        annotation.font = UIFont.systemFont(ofSize: 9)
        annotation.fontColor = .black
        annotation.color = .clear
        page.addAnnotation(annotation)
    }

    private func render(
        _ document: PDFDocument,
        geometry: PDFDocument,
        character: CharacterDocument,
        output: URL
    ) throws {
        let renderer = UIGraphicsPDFRenderer(bounds: document.page(at: 0)?.bounds(for: .mediaBox) ?? .zero)
        try renderer.writePDF(to: output) { rendererContext in
            for index in 0..<document.pageCount {
                guard let page = document.page(at: index) else { continue }
                let bounds = page.bounds(for: .mediaBox)
                rendererContext.beginPage(withBounds: bounds, pageInfo: [:])
                let context = rendererContext.cgContext
                context.saveGState()
                context.translateBy(x: 0, y: bounds.height)
                context.scaleBy(x: 1, y: -1)
                page.draw(with: .mediaBox, to: context)
                context.restoreGState()
                if index == 1 {
                    drawPortrait(character, source: geometry.page(at: 1), bounds: bounds, context: context)
                }
            }
        }
    }

    private func drawPortrait(
        _ character: CharacterDocument,
        source: PDFPage?,
        bounds: CGRect,
        context: CGContext
    ) {
        guard let portrait = character.portrait,
              let url = try? PortraitStore().url(for: portrait),
              let image = UIImage(contentsOfFile: url.path),
              let source,
              let field = source.annotations.first(where: { $0.fieldName == "CHARACTER IMAGE" }) else { return }
        let sourceBounds = source.bounds(for: .mediaBox)
        let rect = CGRect(
            x: field.bounds.minX * bounds.width / sourceBounds.width,
            y: (sourceBounds.height - field.bounds.maxY) * bounds.height / sourceBounds.height,
            width: field.bounds.width * bounds.width / sourceBounds.width,
            height: field.bounds.height * bounds.height / sourceBounds.height
        )
        context.saveGState()
        context.clip(to: rect)
        let scale = max(rect.width / image.size.width, rect.height / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        image.draw(in: CGRect(
            x: rect.midX - size.width / 2,
            y: rect.midY - size.height / 2,
            width: size.width,
            height: size.height
        ))
        context.restoreGState()
    }

    private func template(_ name: String) throws -> PDFDocument {
        guard let url = bundle.url(forResource: name, withExtension: "pdf"), let document = PDFDocument(url: url) else {
            throw RulesCatalogError.resourceMissing("\(name).pdf")
        }
        return document
    }

    private func fieldValues(
        _ character: CharacterDocument,
        catalog: RulesCatalog,
        stats: DerivedCharacterStats
    ) -> [String: String] {
        let balance = character.currencyBalance ?? CurrencyBalance(gold: Int64(character.startingWealthGP ?? 0))
        let equipment = catalog.equipment
            .filter { character.selectedEquipmentIDs.contains($0.id) }
            .map(\.name)
            .joined(separator: ", ")
        let languages = catalog.languages
            .filter { character.selectedLanguageIDs.contains($0.id) }
            .map(\.name)
            .joined(separator: ", ")
        var values = coreFields(character, catalog: catalog, stats: stats)
        values.merge(personalityFields(character)) { _, value in value }
        values["Equipment"] = character.overrides.equipmentText ?? equipment
        values["ProficienciesLang"] = languages
        values["CP"] = String(balance.copper)
        values["SP"] = String(balance.silver)
        values["EP"] = String(balance.electrum)
        values["GP"] = String(balance.gold)
        values["PP"] = String(balance.platinum)
        values["Spellcasting Class 2"] = catalog.characterClass(id: character.classID)?.name ?? ""
        values["SpellSaveDC  2"] = stats.spellSaveDC.map { String($0) } ?? ""
        values["SpellAtkBonus 2"] = stats.spellAttackBonus.map { signed($0) } ?? ""
        values["SpellcastingAbility 2"] = spellcastingAbilityName(character, catalog: catalog)
        let abilityFields: [(AbilityID, (String, String))] = [
            (.strength, ("STR", "STRmod")), (.dexterity, ("DEX", "DEXmod")),
            (.constitution, ("CON", "CONmod")), (.intelligence, ("INT", "INTmod")),
            (.wisdom, ("WIS", "WISmod")), (.charisma, ("CHA", "CHamod"))
        ]
        for (ability, fields) in abilityFields {
            let (score, modifier) = fields
            values[score] = "\(character.totalAbilities[ability])"
            values[modifier] = signed(stats.abilityModifiers[ability, default: 0])
            values["ST \(ability.rawValue.capitalized)"] = signed(stats.savingThrows[ability, default: 0])
        }
        let skillFields = ["animal-handling": "Animal", "sleight-of-hand": "SleightofHand"]
        for skill in catalog.skills {
            values[skillFields[skill.id] ?? skill.id.capitalized] = signed(stats.skills[skill.id, default: 0])
        }
        let spells = catalog.spells.filter { character.selectedSpellIDs.contains($0.id) }
        for (index, spell) in spells.filter({ $0.level == 0 }).enumerated() {
            values["Spells \(1014 + index)"] = spell.name
        }
        for (index, spell) in spells.filter({ $0.level == 1 }).enumerated() {
            values["Spells \(1023 + index)"] = spell.name
        }
        return values
    }

    private func coreFields(
        _ character: CharacterDocument,
        catalog: RulesCatalog,
        stats: DerivedCharacterStats
    ) -> [String: String] {
        var fields: [String: String] = [:]
        fields["CharacterName"] = character.name
        fields["CharacterName 2"] = character.name
        fields["ClassLevel"] = "\(catalog.characterClass(id: character.classID)?.name ?? "") 1"
        fields["Background"] = catalog.background(id: character.backgroundID)?.name ?? ""
        fields["PlayerName"] = character.playerName
        fields["Race"] = catalog.race(id: character.raceID)?.name ?? ""
        fields["Alignment"] = character.alignmentID ?? ""
        fields["XP"] = "0"
        fields["ProfBonus"] = signed(stats.proficiencyBonus)
        fields["AC"] = String(stats.armorClass)
        fields["Initiative"] = signed(stats.initiative)
        fields["Speed"] = String(stats.speed)
        fields["HPMax"] = String(stats.hitPoints)
        fields["HPCurrent"] = String(stats.hitPoints)
        fields["Passive"] = String(stats.passivePerception)
        return fields
    }

    private func personalityFields(_ character: CharacterDocument) -> [String: String] {
        [
            "PersonalityTraits": character.personality.traits,
            "Ideals": character.personality.ideals,
            "Bonds": character.personality.bonds,
            "Flaws": character.personality.flaws,
            "Backstory": character.appearance + "\n" + (character.overrides.notes ?? character.notes)
        ]
    }

    private func spellcastingAbilityName(_ character: CharacterDocument, catalog: RulesCatalog) -> String {
        guard let ability = catalog.characterClass(id: character.classID)?.spellcastingAbility else { return "" }
        let resource = catalog.locale == RulesLocale.spanish.rawValue ? "es" : "en"
        guard let path = bundle.path(forResource: resource, ofType: "lproj"),
              let localizedBundle = Bundle(path: path) else { return ability.rawValue.capitalized }
        return localizedBundle.localizedString(forKey: "ability_\(ability.rawValue)", value: nil, table: nil)
    }

    private var spanishSkillLabels: [String: String] {
        [
            "Acrobatics": "Acrobacias", "Animal": "Trato con animales", "Arcana": "Arcanos",
            "Athletics": "Atletismo", "Deception": "Engaño", "History": "Historia",
            "Insight": "Perspicacia", "Intimidation": "Intimidación", "Investigation": "Investigación",
            "Medicine": "Medicina", "Nature": "Naturaleza", "Perception": "Percepción",
            "Performance": "Interpretación", "Persuasion": "Persuasión", "Religion": "Religión",
            "SleightofHand": "Juego de manos", "Stealth": "Sigilo", "Survival": "Supervivencia"
        ]
    }

    private func signed(_ value: Int) -> String { value >= 0 ? "+\(value)" : "\(value)" }
}
