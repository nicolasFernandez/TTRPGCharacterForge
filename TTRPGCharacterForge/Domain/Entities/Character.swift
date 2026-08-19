//
//  Character.swift
//  TTRPGCharacterForge
//
//  Created by Nicolas Alonso Fernandez Alarcon on 26-12-22.
//

import Foundation

// MARK: - Persisted character document

/// The stable, platform-independent representation used by the editor and local store.
/// Rule catalog entries are referenced by IDs so localized text can change without
/// invalidating existing characters.
struct CharacterDocument: Identifiable, Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1
    static let rulesetID = "dnd5e-srd-2014"

    enum State: String, Codable, Sendable {
        case draft
        case completed
    }

    var id: UUID
    var schemaVersion: Int
    var rulesetID: String
    var state: State
    var createdAt: Date
    var updatedAt: Date
    var currentStep: CharacterCreationStep

    var name: String
    var playerName: String
    var raceID: String?
    var subraceID: String?
    var classID: String?
    var archetypeID: String?
    var backgroundID: String?
    var alignmentID: String?
    var baseAbilities: AbilityScoreSet
    var racialAbilityBonuses: AbilityScoreSet
    var abilityMethod: AbilityAssignmentMethod?
    var selectedSkillIDs: [String]
    var selectedLanguageIDs: [String]
    var selectedEquipmentIDs: [String]
    var startingWealthGP: Int?
    var selectedSpellIDs: [String]
    var personality: CharacterPersonality
    var appearance: String
    var notes: String
    var portrait: PortraitReference?
    var overrides: CharacterOverrides

    init(
        id: UUID = UUID(),
        schemaVersion: Int = Self.currentSchemaVersion,
        rulesetID: String = Self.rulesetID,
        state: State = .draft,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        currentStep: CharacterCreationStep = .identity,
        name: String = "",
        playerName: String = "",
        raceID: String? = nil,
        subraceID: String? = nil,
        classID: String? = nil,
        archetypeID: String? = nil,
        backgroundID: String? = nil,
        alignmentID: String? = nil,
        baseAbilities: AbilityScoreSet = .zero,
        racialAbilityBonuses: AbilityScoreSet = .zero,
        abilityMethod: AbilityAssignmentMethod? = nil,
        selectedSkillIDs: [String] = [],
        selectedLanguageIDs: [String] = [],
        selectedEquipmentIDs: [String] = [],
        startingWealthGP: Int? = nil,
        selectedSpellIDs: [String] = [],
        personality: CharacterPersonality = .init(),
        appearance: String = "",
        notes: String = "",
        portrait: PortraitReference? = nil,
        overrides: CharacterOverrides = .init()
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.rulesetID = rulesetID
        self.state = state
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.currentStep = currentStep
        self.name = name
        self.playerName = playerName
        self.raceID = raceID
        self.subraceID = subraceID
        self.classID = classID
        self.archetypeID = archetypeID
        self.backgroundID = backgroundID
        self.alignmentID = alignmentID
        self.baseAbilities = baseAbilities
        self.racialAbilityBonuses = racialAbilityBonuses
        self.abilityMethod = abilityMethod
        self.selectedSkillIDs = selectedSkillIDs
        self.selectedLanguageIDs = selectedLanguageIDs
        self.selectedEquipmentIDs = selectedEquipmentIDs
        self.startingWealthGP = startingWealthGP
        self.selectedSpellIDs = selectedSpellIDs
        self.personality = personality
        self.appearance = appearance
        self.notes = notes
        self.portrait = portrait
        self.overrides = overrides
    }

    var totalAbilities: AbilityScoreSet { baseAbilities + racialAbilityBonuses }
}

/// An ordered stage in the guided character-creation workflow.
enum CharacterCreationStep: Int, Codable, CaseIterable, Sendable {
    case identity
    case ancestry
    case characterClass
    case background
    case abilities
    case proficiencies
    case equipment
    case spells
    case portrait
    case review
}

/// A stable identifier for one of the six core abilities.
enum AbilityID: String, Codable, CaseIterable, Identifiable, Sendable {
    case strength, dexterity, constitution, intelligence, wisdom, charisma
    var id: String { rawValue }
}

/// A complete set of six ability scores.
struct AbilityScoreSet: Codable, Equatable, Sendable {
    var strength: Int
    var dexterity: Int
    var constitution: Int
    var intelligence: Int
    var wisdom: Int
    var charisma: Int

    static let zero = AbilityScoreSet(
        strength: 0, dexterity: 0, constitution: 0,
        intelligence: 0, wisdom: 0, charisma: 0
    )

    subscript(_ ability: AbilityID) -> Int {
        get {
            switch ability {
            case .strength: strength
            case .dexterity: dexterity
            case .constitution: constitution
            case .intelligence: intelligence
            case .wisdom: wisdom
            case .charisma: charisma
            }
        }
        set {
            switch ability {
            case .strength: strength = newValue
            case .dexterity: dexterity = newValue
            case .constitution: constitution = newValue
            case .intelligence: intelligence = newValue
            case .wisdom: wisdom = newValue
            case .charisma: charisma = newValue
            }
        }
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        var result = lhs
        for ability in AbilityID.allCases { result[ability] += rhs[ability] }
        return result
    }
}

/// A supported method for assigning a character's base ability scores.
enum AbilityAssignmentMethod: String, Codable, CaseIterable, Sendable {
    case standardArray
    case pointBuy
    case rolled
}

/// Free-form role-playing prompts recorded for a character.
struct CharacterPersonality: Codable, Equatable, Sendable {
    var traits: String = ""
    var ideals: String = ""
    var bonds: String = ""
    var flaws: String = ""
}

/// Locates a stored portrait and records the crop used by the UI.
struct PortraitReference: Codable, Equatable, Sendable {
    var relativePath: String
    var crop: NormalizedCrop
}

/// A unit-coordinate crop rectangle independent of image dimensions.
struct NormalizedCrop: Codable, Equatable, Sendable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    static let fullImage = NormalizedCrop(x: 0, y: 0, width: 1, height: 1)
}

/// Optional user-entered values that replace calculated character data.
struct CharacterOverrides: Codable, Equatable, Sendable {
    var armorClass: Int?
    var hitPoints: Int?
    var initiative: Int?
    var savingThrows: [String: Int] = [:]
    var skills: [String: Int] = [:]
    var personality: CharacterPersonality?
    var notes: String?
    var equipmentText: String?
}

/// Legacy in-memory character model retained by the original interface.
struct Character: Identifiable {
    let id: UUID = UUID()
    let name: String
    let race: Race
    let classType: [ClassType]

    let abilities: Abilities
    let skills: Skills

    let background: Background
    var equipment: [Equipment]
    var spells: [Spell] = []

    var armorClass: Int {
        var finalValue: Int = 0
        if equipment.contains(where: { $0 is Armor}) {
            for item in equipment {
                guard let armor = item as? Armor else {
                    continue
                }
                finalValue += armor.armorClass
            }
        } else {
            finalValue = 10 + abilities.dexterity.modifier

        }
        return finalValue
    }
}

extension Character: Equatable {
    static func == (lhs: Character, rhs: Character) -> Bool {
        return lhs.id == rhs.id
    }
}
