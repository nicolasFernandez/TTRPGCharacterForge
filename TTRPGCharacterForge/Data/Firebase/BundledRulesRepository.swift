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
    private let lock = NSLock()
    private let bundle: Bundle
    private var cache: [RulesLocale: RulesCatalog] = [:]

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    // The load/cache/error branches are intentionally kept together for atomic catalog loading.
    // swiftlint:disable:next cyclomatic_complexity
    func catalog(locale: RulesLocale) throws -> RulesCatalog {
        lock.lock(); defer { lock.unlock() }
        if let cached = cache[locale] { return cached }
        let name = "rules_\(locale.rawValue)"
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw RulesCatalogError.resourceMissing("\(name).json")
        }
        do {
            let data = try Data(contentsOf: url)
            let catalog = try JSONDecoder().decode(RulesCatalog.self, from: data)
            guard catalog.locale == locale.rawValue else {
                throw RulesCatalogError.invalidData(
                    NSLocalizedString(
                        "rules_error_locale_mismatch",
                        comment: "Rules catalog locale does not match the requested locale"
                    )
                )
            }
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

extension RulesCatalog {
    /// The only catalog schema understood by this application build.
    static let supportedSchemaVersion = 3
}

/// Verifies cross-references and invariants in a decoded rules catalog.
struct RulesCatalogValidator {
    // swiftlint:disable:next cyclomatic_complexity
    func validate(_ catalog: RulesCatalog) throws {
        guard catalog.schemaVersion == RulesCatalog.supportedSchemaVersion else {
            throw RulesCatalogError.invalidData("schemaVersion")
        }
        guard catalog.rulesetID == CharacterDocument.rulesetID else {
            throw RulesCatalogError.wrongRuleset(catalog.rulesetID)
        }
        try required(catalog.locale, field: "locale")
        try validateText(in: catalog)
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
            for group in rule.equipmentChoiceGroups {
                guard !group.options.isEmpty, group.options.allSatisfy({ !$0.isEmpty }),
                      Set(group.options.map { Set($0) }).count == group.options.count else {
                    throw RulesCatalogError.invalidData(rule.id)
                }
                for option in group.options {
                    try unique(option)
                    try references(option, in: equipment)
                }
            }
        }
        for rule in catalog.races { try references(rule.grantedLanguageIDs, in: languages) }
        for rule in catalog.backgrounds {
            try references(rule.grantedSkillIDs, in: skills)
            try references(rule.grantedLanguageIDs, in: languages)
            try references(rule.grantedEquipmentIDs, in: equipment)
        }
        for spell in catalog.spells {
            guard SpellSchool(rawValue: spell.school) != nil, !spell.classIDs.isEmpty else {
                throw RulesCatalogError.invalidData(spell.id)
            }
            try validateMechanics(of: spell)
            try unique(spell.classIDs)
            try references(spell.classIDs, in: classes)
        }
        try catalog.equipment.forEach(validateDamage)
    }

    private func unique(_ ids: [String]) throws {
        var seen = Set<String>()
        for id in ids {
            try required(id, field: "id")
            guard seen.insert(id).inserted else { throw RulesCatalogError.duplicateID(id) }
        }
    }

    private func references(_ values: [String], in allowed: Set<String>) throws {
        try values.forEach { try required($0, field: "reference") }
        if let unknown = values.first(where: { !allowed.contains($0) }) {
            throw RulesCatalogError.danglingReference(unknown)
        }
    }

    private func validateMechanics(of spell: SpellRule) throws {
        guard spell.castingTimeMechanic.amount > 0, !spell.componentSet.isEmpty,
              spell.hasHigherLevels == (spell.higherLevels != nil) else {
            throw RulesCatalogError.invalidData("spells.\(spell.id).mechanics")
        }
        try validateRange(of: spell)
        try validateDuration(of: spell)
    }

    private func validateDamage(of item: EquipmentRule) throws {
        guard (item.damageDice == nil) == (item.damageType == nil) else {
            throw RulesCatalogError.invalidData("equipment.\(item.id).damage")
        }
        if let dice = item.damageDice, dice.numberOfDice <= 0 || dice.sides <= 0 {
            throw RulesCatalogError.invalidData("equipment.\(item.id).damageDice")
        }
    }

    private func validateRange(of spell: SpellRule) throws {
        switch spell.rangeMechanic.kind {
        case .distance:
            guard let distance = spell.rangeMechanic.distanceFeet, distance > 0 else {
                throw RulesCatalogError.invalidData("spells.\(spell.id).rangeMechanic")
            }
        case .selfRange, .touch:
            guard spell.rangeMechanic.distanceFeet == nil else {
                throw RulesCatalogError.invalidData("spells.\(spell.id).rangeMechanic")
            }
        }
    }

    private func validateDuration(of spell: SpellRule) throws {
        switch spell.durationMechanic.kind {
        case .timed:
            guard let amount = spell.durationMechanic.amount, amount > 0, spell.durationMechanic.unit != nil else {
                throw RulesCatalogError.invalidData("spells.\(spell.id).durationMechanic")
            }
        case .instantaneous, .permanent, .special:
            guard spell.durationMechanic.amount == nil, spell.durationMechanic.unit == nil else {
                throw RulesCatalogError.invalidData("spells.\(spell.id).durationMechanic")
            }
        }
    }

    private func validateText(in catalog: RulesCatalog) throws {
        try catalog.races.forEach(validateText)
        try catalog.classes.forEach(validateText)
        try catalog.backgrounds.forEach(validateText)
        for rule in catalog.skills { try required(rule.name, field: "skills.\(rule.id).name") }
        try namedRules(catalog.languages, field: "languages")
        for rule in catalog.equipment { try required(rule.name, field: "equipment.\(rule.id).name") }
        try catalog.spells.forEach(validateText)
    }

    private func validateText(of rule: RaceRule) throws {
        try required(rule.name, field: "races.\(rule.id).name")
        try required(rule.description, field: "races.\(rule.id).description")
        try namedRules(rule.subraces, field: "races.\(rule.id).subraces")
        try unique(rule.featureIDs)
    }

    private func validateText(of rule: ClassRule) throws {
        try required(rule.name, field: "classes.\(rule.id).name")
        try required(rule.description, field: "classes.\(rule.id).description")
        try namedRules(rule.archetypes, field: "classes.\(rule.id).archetypes")
    }

    private func validateText(of rule: BackgroundRule) throws {
        try required(rule.name, field: "backgrounds.\(rule.id).name")
        try required(rule.description, field: "backgrounds.\(rule.id).description")
        try required(rule.featureName, field: "backgrounds.\(rule.id).featureName")
    }

    private func validateText(of rule: SpellRule) throws {
        try required(rule.name, field: "spells.\(rule.id).name")
        try required(rule.castingTime, field: "spells.\(rule.id).castingTime")
        try required(rule.range, field: "spells.\(rule.id).range")
        try required(rule.components, field: "spells.\(rule.id).components")
        try required(rule.duration, field: "spells.\(rule.id).duration")
        try required(rule.description, field: "spells.\(rule.id).description")
        if let higherLevels = rule.higherLevels {
            try required(higherLevels, field: "spells.\(rule.id).higherLevels")
        }
    }

    private func namedRules(_ rules: [NamedRule], field: String) throws {
        try unique(rules.map(\.id))
        for rule in rules {
            try required(rule.name, field: "\(field).\(rule.id).name")
            if let description = rule.description {
                try required(description, field: "\(field).\(rule.id).description")
            }
        }
    }

    private func required(_ value: String, field: String) throws {
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RulesCatalogError.invalidData(field)
        }
    }
}

/// Compares stable identifiers and non-localized mechanics without deciding translation policy.
struct BilingualRulesCatalogValidator {
    func validate(english: RulesCatalog, spanish: RulesCatalog) throws {
        try RulesCatalogValidator().validate(english)
        try RulesCatalogValidator().validate(spanish)
        guard english.locale == RulesLocale.english.rawValue,
              spanish.locale == RulesLocale.spanish.rawValue else {
            throw RulesCatalogError.invalidData("bilingual.locale")
        }
        try equal(english.schemaVersion, spanish.schemaVersion, field: "schemaVersion")
        try equal(english.rulesetID, spanish.rulesetID, field: "rulesetID")
        try paired(english.races, spanish.races, section: "races") { left, right in
            left.speed == right.speed && left.abilityBonuses == right.abilityBonuses
                && left.subraces.map(\.id) == right.subraces.map(\.id)
                && left.grantedLanguageIDs == right.grantedLanguageIDs
                && left.additionalLanguageChoices == right.additionalLanguageChoices
                && left.featureIDs == right.featureIDs
        }
        try paired(english.classes, spanish.classes, section: "classes") { left, right in
            left.hitDie == right.hitDie && left.savingThrowAbilities == right.savingThrowAbilities
                && left.skillChoiceCount == right.skillChoiceCount
                && left.availableSkillIDs == right.availableSkillIDs
                && left.archetypes.map(\.id) == right.archetypes.map(\.id)
                && left.equipmentChoiceGroups == right.equipmentChoiceGroups
                && left.startingWealth == right.startingWealth
                && left.spellcastingAbility == right.spellcastingAbility
                && left.cantripsKnown == right.cantripsKnown
                && left.spellsKnownOrPrepared == right.spellsKnownOrPrepared
        }
        try paired(english.backgrounds, spanish.backgrounds, section: "backgrounds") { left, right in
            left.grantedSkillIDs == right.grantedSkillIDs
                && left.grantedLanguageIDs == right.grantedLanguageIDs
                && left.additionalLanguageChoices == right.additionalLanguageChoices
                && left.grantedEquipmentIDs == right.grantedEquipmentIDs
        }
        try paired(english.skills, spanish.skills, section: "skills") { $0.ability == $1.ability }
        try paired(english.languages, spanish.languages, section: "languages") { _, _ in true }
        try paired(english.equipment, spanish.equipment, section: "equipment") { left, right in
            left.kind == right.kind && left.armorClass == right.armorClass
                && left.dexterityCap == right.dexterityCap
                && left.damageDice == right.damageDice && left.damageType == right.damageType
                && left.weight == right.weight && left.costGP == right.costGP
        }
        try paired(english.spells, spanish.spells, section: "spells") { left, right in
            left.level == right.level && left.school == right.school
                && left.castingTimeMechanic == right.castingTimeMechanic
                && left.rangeMechanic == right.rangeMechanic
                && left.componentSet == right.componentSet
                && left.durationMechanic == right.durationMechanic
                && left.hasHigherLevels == right.hasHigherLevels
                && left.classIDs == right.classIDs && left.ritual == right.ritual
                && left.concentration == right.concentration
        }
    }

    private func paired<Rule: Identifiable>(
        _ english: [Rule],
        _ spanish: [Rule],
        section: String,
        compatible: (Rule, Rule) -> Bool
    ) throws where Rule.ID == String {
        let englishByID = Dictionary(uniqueKeysWithValues: english.map { ($0.id, $0) })
        let spanishByID = Dictionary(uniqueKeysWithValues: spanish.map { ($0.id, $0) })
        guard englishByID.keys.sorted() == spanishByID.keys.sorted() else {
            throw RulesCatalogError.invalidData("bilingual.\(section).ids")
        }
        for id in englishByID.keys.sorted() {
            guard let left = englishByID[id], let right = spanishByID[id], compatible(left, right) else {
                throw RulesCatalogError.invalidData("bilingual.\(section).\(id)")
            }
        }
    }

    private func equal<Value: Equatable>(_ left: Value, _ right: Value, field: String) throws {
        guard left == right else { throw RulesCatalogError.invalidData("bilingual.\(field)") }
    }
}
