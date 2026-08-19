//
//  RulesRepository.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

/// Loads a localized catalog of game rules.
protocol RulesRepository {
    func catalog(locale: RulesLocale) throws -> RulesCatalog
}

/// A supported locale for bundled rules content.
enum RulesLocale: String, Codable, Sendable {
    case english = "en"
    case spanish = "es"

    static var current: Self {
        Locale.preferredLanguages.first?.hasPrefix("es") == true ? .spanish : .english
    }
}

/// The complete set of rules needed to create and validate a character.
struct RulesCatalog: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var rulesetID: String
    var locale: String
    var races: [RaceRule]
    var classes: [ClassRule]
    var backgrounds: [BackgroundRule]
    var skills: [SkillRule]
    var languages: [NamedRule]
    var equipment: [EquipmentRule]
    var spells: [SpellRule]

    func race(id: String?) -> RaceRule? { races.first { $0.id == id } }
    func characterClass(id: String?) -> ClassRule? { classes.first { $0.id == id } }
    func background(id: String?) -> BackgroundRule? { backgrounds.first { $0.id == id } }
}

/// A lightweight rule option identified by a stable catalog ID.
struct NamedRule: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var name: String
    var description: String?
}

/// Rules and selectable options associated with a playable ancestry.
struct RaceRule: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var name: String
    var description: String
    var speed: Int
    var abilityBonuses: AbilityScoreSet
    var subraces: [NamedRule]
    var grantedLanguageIDs: [String]
    var additionalLanguageChoices: Int
    var featureIDs: [String]
}

/// Rules and selectable options associated with a character class.
struct ClassRule: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var name: String
    var description: String
    var hitDie: Int
    var savingThrowAbilities: [AbilityID]
    var skillChoiceCount: Int
    var availableSkillIDs: [String]
    var archetypes: [NamedRule]
    var equipmentChoiceGroups: [[String]]
    var startingWealth: DiceFormula
    var spellcastingAbility: AbilityID?
    var cantripsKnown: Int
    var spellsKnownOrPrepared: Int
}

/// Rules and proficiencies granted by a character background.
struct BackgroundRule: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var name: String
    var description: String
    var grantedSkillIDs: [String]
    var grantedLanguageIDs: [String]
    var additionalLanguageChoices: Int
    var grantedEquipmentIDs: [String]
    var featureName: String
}

/// Describes a skill and the ability used for its checks.
struct SkillRule: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var name: String
    var ability: AbilityID
}

/// Describes an equipment option and its mechanical properties.
struct EquipmentRule: Codable, Equatable, Identifiable, Sendable {
    enum Kind: String, Codable, Sendable { case armor, weapon, gear, pack, tool }
    var id: String
    var name: String
    var kind: Kind
    var armorClass: Int?
    var dexterityCap: Int?
    var damage: String?
    var weight: Double
    var costGP: Double
}

/// Describes a spell available in the rules catalog.
struct SpellRule: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var name: String
    var level: Int
    var school: String
    var castingTime: String
    var range: String
    var components: String
    var duration: String
    var description: String
    var higherLevels: String?
    var classIDs: [String]
    var ritual: Bool
    var concentration: Bool
}

/// Represents a conventional dice expression such as `2d6 + 3`.
struct DiceFormula: Codable, Equatable, Sendable {
    var count: Int
    var sides: Int
    var multiplier: Int
}

/// Reports malformed or inconsistent bundled rules data.
enum RulesCatalogError: LocalizedError, Equatable {
    case resourceMissing(String)
    case invalidData(String)
    case wrongRuleset(String)
    case duplicateID(String)
    case danglingReference(String)
    case incompleteTranslation(String)

    var errorDescription: String? {
        switch self {
        case .resourceMissing(let value): "Missing rules resource: \(value)"
        case .invalidData(let value): "Invalid rules data: \(value)"
        case .wrongRuleset(let value): "Unsupported ruleset: \(value)"
        case .duplicateID(let value): "Duplicate rule ID: \(value)"
        case .danglingReference(let value): "Unknown rule reference: \(value)"
        case .incompleteTranslation(let value): "Missing localized rules text: \(value)"
        }
    }
}
