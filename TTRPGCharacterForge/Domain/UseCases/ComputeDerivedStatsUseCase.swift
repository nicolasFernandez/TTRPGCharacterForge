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
        let equippedArmor = catalog.equipment
            .filter { character.selectedEquipmentIDs.contains($0.id) && $0.kind == .armor }
            .max { ($0.armorClass ?? 0) < ($1.armorClass ?? 0) }
        guard let armor = equippedArmor, let base = armor.armorClass else {
            return 10 + dexterityModifier
        }
        return base + min(dexterityModifier, armor.dexterityCap ?? dexterityModifier)
    }
}

/// A user-correctable problem found while validating a character.
enum CharacterValidationError: LocalizedError, Equatable {
    case missingRequiredChoice(String)
    case invalidAbilityScores
    case invalidSkillCount(expected: Int, actual: Int)
    case invalidSpell(String)
    case invalidEquipment

    //FIXME: Localize validation errors and avoid exposing internal field identifiers to users. + https://github.com/nicolasFernandez/TTRPGCharacterForge/pull/115#discussion_r3814262869
    var errorDescription: String? {
        switch self {
        case .missingRequiredChoice(let field): "Choose a value for \(field)."
        case .invalidAbilityScores: "Ability scores do not match the selected assignment method."
        case .invalidSkillCount(let expected, let actual): "Choose \(expected) class skills; currently selected: \(actual)."
        case .invalidSpell(let spell): "The spell \(spell) is not available to this character."
        case .invalidEquipment: "Choose either valid starting equipment or starting wealth."
        }
    }
}
