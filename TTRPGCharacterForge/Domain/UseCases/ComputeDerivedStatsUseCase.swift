//
//  ComputeDerivedStatsUseCase.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

/// Rules-derived values displayed on a completed character sheet.
struct DerivedCharacterStats: Equatable, Sendable {
    var proficiencyBonus: Int
    var abilityModifiers: [AbilityID: Int]
    var savingThrows: [AbilityID: Int]
    var skills: [String: Int]
    var passivePerception: Int
    var initiative: Int
    var armorClass: Int
    var hitPoints: Int
    var speed: Int
    var spellSaveDC: Int?
    var spellAttackBonus: Int?
}

/// Calculates combat, skill, saving throw, and spellcasting statistics.
struct ComputeDerivedStatsUseCase {
    func execute(character: CharacterDocument, catalog: RulesCatalog) throws -> DerivedCharacterStats {
        guard let race = catalog.race(id: character.raceID) else {
            throw CharacterValidationError.missingRequiredChoice("race")
        }
        guard let characterClass = catalog.characterClass(id: character.classID) else {
            throw CharacterValidationError.missingRequiredChoice("class")
        }

        let scores = character.totalAbilities
        let modifiers = Dictionary(uniqueKeysWithValues: AbilityID.allCases.map {
            ($0, Self.modifier(for: scores[$0]))
        })
        let proficiencyBonus = 2
        let selectedSkills = Set(character.selectedSkillIDs)
        let skills = Dictionary(uniqueKeysWithValues: catalog.skills.map { skill in
            let proficiency = selectedSkills.contains(skill.id) ? proficiencyBonus : 0
            return (skill.id, modifiers[skill.ability, default: 0] + proficiency)
        })
        let savingThrows = Dictionary(uniqueKeysWithValues: AbilityID.allCases.map { ability in
            let proficiency = characterClass.savingThrowAbilities.contains(ability) ? proficiencyBonus : 0
            return (ability, modifiers[ability, default: 0] + proficiency)
        })

        let armorClass = calculatedArmorClass(
            character: character,
            catalog: catalog,
            dexterityModifier: modifiers[.dexterity, default: 0]
        )
        let hitPoints = max(1, characterClass.hitDie + modifiers[.constitution, default: 0])
        let spellModifier = characterClass.spellcastingAbility.map { modifiers[$0, default: 0] }

        return DerivedCharacterStats(
            proficiencyBonus: proficiencyBonus,
            abilityModifiers: modifiers,
            savingThrows: savingThrows,
            skills: skills,
            passivePerception: 10 + skills["perception", default: modifiers[.wisdom, default: 0]],
            initiative: character.overrides.initiative ?? modifiers[.dexterity, default: 0],
            armorClass: character.overrides.armorClass ?? armorClass,
            hitPoints: character.overrides.hitPoints ?? hitPoints,
            speed: race.speed,
            spellSaveDC: spellModifier.map { 8 + proficiencyBonus + $0 },
            spellAttackBonus: spellModifier.map { proficiencyBonus + $0 }
        )
    }

    static func modifier(for score: Int) -> Int {
        Int(floor(Double(score - 10) / 2.0))
    }

    private func calculatedArmorClass(
        character: CharacterDocument,
        catalog: RulesCatalog,
        dexterityModifier: Int
    ) -> Int {
        let equippedItems = catalog.equipment.filter { character.selectedEquipmentIDs.contains($0.id) }
        let equippedArmor = equippedItems
            .filter { $0.kind == .armor && $0.id != "shield" && $0.id != "wooden-shield" }
            .max { ($0.armorClass ?? 0) < ($1.armorClass ?? 0) }
        let shieldBonus = equippedItems
            .filter { $0.id == "shield" || $0.id == "wooden-shield" }
            .map { $0.armorClass ?? 0 }
            .max() ?? 0
        guard let armor = equippedArmor, let base = armor.armorClass else {
            return 10 + dexterityModifier + shieldBonus
        }
        return base + min(dexterityModifier, armor.dexterityCap ?? dexterityModifier) + shieldBonus
    }
}

/// A user-correctable problem found while validating a character.
enum CharacterValidationError: LocalizedError, Equatable {
    case missingRequiredChoice(String)
    case invalidAbilityScores
    case invalidSkillCount(expected: Int, actual: Int)
    case invalidSpell(String)
    case duplicateSpellSelection
    case spellCountExceeded(cantrips: Int, leveled: Int)
    case invalidEquipment

    var errorDescription: String? {
        switch self {
        case let .missingRequiredChoice(field):
            // Prefer a user-facing localized field label (e.g. "character_race") and fall back to
            // a generic validation message if no friendly label exists for the internal id.
            let fieldKey = "character_\(field)"
            let localizedField = NSLocalizedString(fieldKey, comment: "Field label for validation messages")
            if localizedField != fieldKey {
                return String(
                    format: NSLocalizedString(
                        "validation_missing_choice_for_field",
                        comment: "Validation: missing required choice for a specific field (1 param: field label)"
                    ),
                    localizedField
                )
            }
            return NSLocalizedString(
                "validation_missing_choice_generic",
                comment: "Validation: missing required choice (generic)"
            )
        case .invalidAbilityScores:
            return NSLocalizedString(
                "validation_invalid_ability_scores",
                comment: "Validation: ability scores do not match selected assignment method"
            )
        case let .invalidSkillCount(expected, actual):
            return String(
                format: NSLocalizedString(
                    "validation_invalid_skill_count",
                    comment: "Validation: wrong number of class skills (2 params: expected, actual)"
                ),
                expected,
                actual
            )
        case .invalidSpell(let spell):
            return String(
                format: NSLocalizedString(
                    "validation_invalid_spell",
                    comment: "Validation: selected spell is not available (1 param: spell name)"
                ),
                spell
            )
        case .duplicateSpellSelection:
            return NSLocalizedString(
                "validation_duplicate_spell_selection",
                comment: "Validation: the same spell was selected more than once"
            )
        case let .spellCountExceeded(cantrips, leveled):
            return String(
                format: NSLocalizedString(
                    "validation_spell_count_exceeded",
                    comment: "Validation: selected spell counts exceed the class limits"
                ),
                cantrips,
                leveled
            )
        case .invalidEquipment:
            return NSLocalizedString("validation_invalid_equipment", comment: "Validation: invalid equipment selection")
        }
    }
}
