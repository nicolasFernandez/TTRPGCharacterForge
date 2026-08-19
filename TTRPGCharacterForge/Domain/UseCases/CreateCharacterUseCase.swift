//
//  CreateCharacterUseCase.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

/// Creates a new draft character with the current schema defaults.
struct CreateCharacterUseCase {
    private let abilityService = AbilityAssignmentService()

    func makeDraft() -> CharacterDocument { CharacterDocument() }

    func validateForCompletion(
        _ character: CharacterDocument,
        catalog: RulesCatalog
    ) throws {
        guard !character.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CharacterValidationError.missingRequiredChoice("name")
        }
        guard let race = catalog.race(id: character.raceID) else {
            throw CharacterValidationError.missingRequiredChoice("race")
        }
        guard let characterClass = catalog.characterClass(id: character.classID) else {
            throw CharacterValidationError.missingRequiredChoice("class")
        }
        guard catalog.background(id: character.backgroundID) != nil else {
            throw CharacterValidationError.missingRequiredChoice("background")
        }
        if !race.subraces.isEmpty && character.subraceID == nil {
            throw CharacterValidationError.missingRequiredChoice("subrace")
        }
        if !characterClass.archetypes.isEmpty && character.archetypeID == nil {
            throw CharacterValidationError.missingRequiredChoice("archetype")
        }
        guard let method = character.abilityMethod,
              abilityService.validate(character.baseAbilities, method: method) else {
            throw CharacterValidationError.invalidAbilityScores
        }
        let backgroundSkills = Set(catalog.background(id: character.backgroundID)?.grantedSkillIDs ?? [])
        let classSkills = Set(character.selectedSkillIDs).subtracting(backgroundSkills)
        guard classSkills.count == characterClass.skillChoiceCount else {
            throw CharacterValidationError.invalidSkillCount(
                expected: characterClass.skillChoiceCount,
                actual: classSkills.count
            )
        }
        guard !character.selectedEquipmentIDs.isEmpty || character.startingWealthGP != nil else {
            throw CharacterValidationError.invalidEquipment
        }
        for spellID in character.selectedSpellIDs {
            guard let spell = catalog.spells.first(where: { $0.id == spellID }),
                  spell.classIDs.contains(characterClass.id), spell.level <= 1 else {
                throw CharacterValidationError.invalidSpell(spellID)
            }
        }
    }
}
