//
//  BundledRulesRepository.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

/// Loads the immutable SRD catalog bundled with the application. The historical
/// filename remains only because it already belongs to the Xcode target.
final class BundledRulesRepository: RulesRepository {
    private let bundle: Bundle
    private var cache: [RulesLocale: RulesCatalog] = [:]

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func catalog(locale: RulesLocale) throws -> RulesCatalog {
        if let cached = cache[locale] { return cached }
        let name = "rules_\(locale.rawValue)"
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw RulesCatalogError.resourceMissing("\(name).json")
        }
        do {
            let data = try Data(contentsOf: url)
            let catalog = try JSONDecoder().decode(RulesCatalog.self, from: data)
            try RulesCatalogValidator().validate(catalog)
            cache[locale] = catalog
            return catalog
        } catch let error as RulesCatalogError {
            throw error
        } catch {
            throw RulesCatalogError.invalidData(error.localizedDescription)
        }
    }
}

/// Verifies cross-references and invariants in a decoded rules catalog.
struct RulesCatalogValidator {
    func validate(_ catalog: RulesCatalog) throws {
        guard catalog.rulesetID == CharacterDocument.rulesetID else {
            throw RulesCatalogError.wrongRuleset(catalog.rulesetID)
        }
        try unique(catalog.races.map(\.id))
        try unique(catalog.classes.map(\.id))
        try unique(catalog.backgrounds.map(\.id))
        try unique(catalog.skills.map(\.id))
        try unique(catalog.languages.map(\.id))
        try unique(catalog.equipment.map(\.id))
        try unique(catalog.spells.map(\.id))

        let skills = Set(catalog.skills.map(\.id))
        let languages = Set(catalog.languages.map(\.id))
        let equipment = Set(catalog.equipment.map(\.id))
        let classes = Set(catalog.classes.map(\.id))
        for rule in catalog.classes {
            try references(rule.availableSkillIDs, in: skills)
            try references(rule.equipmentChoiceGroups.flatMap { $0 }, in: equipment)
        }
        for rule in catalog.races { try references(rule.grantedLanguageIDs, in: languages) }
        for rule in catalog.backgrounds {
            try references(rule.grantedSkillIDs, in: skills)
            try references(rule.grantedLanguageIDs, in: languages)
            try references(rule.grantedEquipmentIDs, in: equipment)
        }
        for spell in catalog.spells { try references(spell.classIDs, in: classes) }
    }

    private func unique(_ ids: [String]) throws {
        var seen = Set<String>()
        for id in ids where !seen.insert(id).inserted {
            throw RulesCatalogError.duplicateID(id)
        }
    }

    private func references(_ values: [String], in allowed: Set<String>) throws {
        if let unknown = values.first(where: { !allowed.contains($0) }) {
            throw RulesCatalogError.danglingReference(unknown)
        }
    }
}
