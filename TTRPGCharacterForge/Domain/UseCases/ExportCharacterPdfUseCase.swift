//
//  ExportCharacterPdfUseCase.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

/// Coordinates character validation and PDF export.
struct ExportCharacterPdfUseCase {
    private let exporter: PdfExporter

    init(exporter: PdfExporter = CharacterSheetPDFExporter()) {
        self.exporter = exporter
    }

    func execute(character: CharacterDocument, catalog: RulesCatalog) throws -> URL {
        try exporter.export(character, catalog: catalog)
    }
}

#if canImport(UIKit)
import UIKit

/// Renders a character sheet as a shareable PDF file.
struct CharacterSheetPDFExporter: PdfExporter {
    private let rulesEngine = ComputeDerivedStatsUseCase()
    private let portraitStore = PortraitStore()
    private let page = CGRect(x: 0, y: 0, width: 612, height: 792)

    func export(_ character: CharacterDocument, catalog: RulesCatalog) throws -> URL {
        let stats = try rulesEngine.execute(character: character, catalog: catalog)
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(sanitized(character.name))-character-sheet.pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        try renderer.writePDF(to: output) { context in
            drawCorePage(context: context, character: character, catalog: catalog, stats: stats)
            drawDetailsPage(context: context, character: character, catalog: catalog)
            if stats.spellSaveDC != nil {
                drawSpellsPage(context: context, character: character, catalog: catalog, stats: stats)
            }
        }
        return output
    }

    private func drawCorePage(
        context: UIGraphicsPDFRendererContext,
        character: CharacterDocument,
        catalog: RulesCatalog,
        stats: DerivedCharacterStats
    ) {
        context.beginPage()
        title(character.name.isEmpty ? "TTRPG Character" : character.name, y: 36)
        value("Class", catalog.characterClass(id: character.classID)?.name ?? "—", x: 36, y: 82, width: 170)
        value("Race", catalog.race(id: character.raceID)?.name ?? "—", x: 220, y: 82, width: 170)
        value("Background", catalog.background(id: character.backgroundID)?.name ?? "—", x: 404, y: 82, width: 170)

        var y: CGFloat = 140
        for ability in AbilityID.allCases {
            let score = character.totalAbilities[ability]
            let modifier = stats.abilityModifiers[ability, default: 0]
            box(title: ability.rawValue.capitalized, value: "\(score)  (\(signed(modifier)))", x: 36, y: y, width: 150)
            y += 62
        }
        box(title: "Armor Class", value: "\(stats.armorClass)", x: 220, y: 140, width: 100)
        box(title: "Initiative", value: signed(stats.initiative), x: 330, y: 140, width: 100)
        box(title: "Speed", value: "\(stats.speed) ft", x: 440, y: 140, width: 100)
        box(title: "Hit Points", value: "\(stats.hitPoints)", x: 220, y: 210, width: 320)
        box(title: "Proficiency", value: signed(stats.proficiencyBonus), x: 220, y: 280, width: 150)
        box(title: "Passive Perception", value: "\(stats.passivePerception)", x: 390, y: 280, width: 150)

        section("Saving Throws", x: 220, y: 350, width: 150)
        var saveY: CGFloat = 380
        for ability in AbilityID.allCases {
            text("\(ability.rawValue.capitalized): \(signed(stats.savingThrows[ability, default: 0]))", x: 226, y: saveY, width: 145)
            saveY += 22
        }
        section("Skills", x: 390, y: 350, width: 184)
        var skillY: CGFloat = 380
        for skill in catalog.skills {
            text("\(skill.name): \(signed(stats.skills[skill.id, default: 0]))", x: 396, y: skillY, width: 178, size: 9)
            skillY += 17
        }
        footer()
    }

    private func drawDetailsPage(
        context: UIGraphicsPDFRendererContext,
        character: CharacterDocument,
        catalog: RulesCatalog
    ) {
        context.beginPage()
        title("Character Details", y: 36)
        section("Portrait", x: 36, y: 90, width: 250)
        if let portrait = character.portrait,
           let image = UIImage(contentsOfFile: portraitStore.url(for: portrait).path) {
            drawAspectFill(image, in: CGRect(x: 42, y: 122, width: 238, height: 210))
        }
        section("Appearance", x: 36, y: 350, width: 250)
        paragraph(character.appearance, x: 42, y: 382, width: 238, height: 110)
        section("Personality Traits", x: 306, y: 90, width: 270)
        paragraph(character.personality.traits, x: 312, y: 122, width: 258, height: 70)
        section("Ideals", x: 306, y: 210, width: 270)
        paragraph(character.personality.ideals, x: 312, y: 242, width: 258, height: 60)
        section("Bonds", x: 306, y: 320, width: 270)
        paragraph(character.personality.bonds, x: 312, y: 352, width: 258, height: 60)
        section("Flaws", x: 306, y: 430, width: 270)
        paragraph(character.personality.flaws, x: 312, y: 462, width: 258, height: 60)
        section("Equipment", x: 36, y: 510, width: 250)
        let equipment = character.overrides.equipmentText ?? catalog.equipment
            .filter { character.selectedEquipmentIDs.contains($0.id) }.map(\.name).joined(separator: ", ")
        paragraph(equipment, x: 42, y: 542, width: 238, height: 180)
        section("Notes", x: 306, y: 540, width: 270)
        paragraph(character.overrides.notes ?? character.notes, x: 312, y: 572, width: 258, height: 150)
        footer()
    }

    private func drawSpellsPage(
        context: UIGraphicsPDFRendererContext,
        character: CharacterDocument,
        catalog: RulesCatalog,
        stats: DerivedCharacterStats
    ) {
        context.beginPage()
        title("Spellcasting", y: 36)
        value("Ability", catalog.characterClass(id: character.classID)?.spellcastingAbility?.rawValue.capitalized ?? "—", x: 36, y: 82, width: 170)
        value("Save DC", "\(stats.spellSaveDC ?? 0)", x: 220, y: 82, width: 170)
        value("Attack Bonus", signed(stats.spellAttackBonus ?? 0), x: 404, y: 82, width: 170)
        var y: CGFloat = 140
        for spell in catalog.spells.filter({ character.selectedSpellIDs.contains($0.id) }) {
            section("\(spell.name) · \(spell.level == 0 ? "Cantrip" : "Level \(spell.level)")", x: 36, y: y, width: 540)
            paragraph(spell.description, x: 42, y: y + 32, width: 528, height: 55)
            y += 98
            if y > 700 { break }
        }
        footer()
    }

    private func title(_ value: String, y: CGFloat) {
        text(value, x: 36, y: y, width: 540, size: 24, weight: .bold)
        UIColor.label.setStroke(); UIBezierPath(rect: CGRect(x: 36, y: y + 34, width: 540, height: 1)).stroke()
    }

    private func section(_ value: String, x: CGFloat, y: CGFloat, width: CGFloat) {
        UIColor.systemGray5.setFill(); UIBezierPath(roundedRect: CGRect(x: x, y: y, width: width, height: 26), cornerRadius: 5).fill()
        text(value, x: x + 6, y: y + 5, width: width - 12, size: 11, weight: .bold)
    }

    private func box(title: String, value: String, x: CGFloat, y: CGFloat, width: CGFloat) {
        UIColor.secondaryLabel.setStroke(); UIBezierPath(roundedRect: CGRect(x: x, y: y, width: width, height: 52), cornerRadius: 7).stroke()
        text(title, x: x + 6, y: y + 5, width: width - 12, size: 9, weight: .bold)
        text(value, x: x + 6, y: y + 23, width: width - 12, size: 15)
    }

    private func value(_ label: String, _ value: String, x: CGFloat, y: CGFloat, width: CGFloat) {
        text(label.uppercased(), x: x, y: y, width: width, size: 8, weight: .bold)
        text(value, x: x, y: y + 14, width: width, size: 13)
    }

    private func paragraph(_ value: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        let style = NSMutableParagraphStyle(); style.lineBreakMode = .byWordWrapping
        (value as NSString).draw(in: CGRect(x: x, y: y, width: width, height: height), withAttributes: [.font: UIFont.systemFont(ofSize: 10), .paragraphStyle: style])
    }

    private func text(_ value: String, x: CGFloat, y: CGFloat, width: CGFloat, size: CGFloat = 11, weight: UIFont.Weight = .regular) {
        (value as NSString).draw(in: CGRect(x: x, y: y, width: width, height: size + 6), withAttributes: [.font: UIFont.systemFont(ofSize: size, weight: weight)])
    }

    private func footer() {
        text("TTRPGCharacterForge · SRD 5.1 · CC BY 4.0", x: 36, y: 760, width: 540, size: 8)
    }

    private func drawAspectFill(_ image: UIImage, in rect: CGRect) {
        let scale = max(rect.width / image.size.width, rect.height / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let drawingRect = CGRect(
            x: rect.midX - size.width / 2,
            y: rect.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
        UIGraphicsGetCurrentContext()?.saveGState()
        UIBezierPath(roundedRect: rect, cornerRadius: 8).addClip()
        image.draw(in: drawingRect)
        UIGraphicsGetCurrentContext()?.restoreGState()
    }

    private func signed(_ value: Int) -> String { value >= 0 ? "+\(value)" : "\(value)" }
    private func sanitized(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let result = value.unicodeScalars.map { allowed.contains($0) ? String($0) : "-" }.joined()
        return result.isEmpty ? "character" : result
    }
}
#endif
