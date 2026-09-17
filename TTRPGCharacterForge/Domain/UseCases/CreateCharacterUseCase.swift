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
        try validateCoreChoices(character, catalog: catalog)
        guard let race = catalog.race(id: character.raceID) else {
            throw CharacterValidationError.missingRequiredChoice("race")
        }
        guard let characterClass = catalog.characterClass(id: character.classID) else {
            throw CharacterValidationError.missingRequiredChoice("class")
        }
        try validateSubrace(character.subraceID, against: race)
        try validateArchetype(character.archetypeID, against: characterClass)
        try validateSkills(character, characterClass: characterClass, catalog: catalog)
        try validateEquipment(character, characterClass: characterClass, catalog: catalog)
        try validateSpells(character, characterClass: characterClass, catalog: catalog)
    }

    private func validateCoreChoices(_ character: CharacterDocument, catalog: RulesCatalog) throws {
        guard !character.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CharacterValidationError.missingRequiredChoice("name")
        }
        guard catalog.background(id: character.backgroundID) != nil else {
            throw CharacterValidationError.missingRequiredChoice("background")
        }
        guard let method = character.abilityMethod,
              abilityService.validate(character.baseAbilities, method: method) else {
            throw CharacterValidationError.invalidAbilityScores
        }
    }

    private func validateSubrace(_ id: String?, against race: RaceRule) throws {
        if !race.subraces.isEmpty && id == nil {
            throw CharacterValidationError.missingRequiredChoice("subrace")
        }
        if let id, !race.subraces.contains(where: { $0.id == id }) {
            throw CharacterValidationError.missingRequiredChoice("subrace")
        }
    }

    private func validateArchetype(_ id: String?, against characterClass: ClassRule) throws {
        if !characterClass.archetypes.isEmpty && id == nil {
            throw CharacterValidationError.missingRequiredChoice("archetype")
        }
        if let id, !characterClass.archetypes.contains(where: { $0.id == id }) {
            throw CharacterValidationError.missingRequiredChoice("archetype")
        }
    }

    private func validateSkills(
        _ character: CharacterDocument,
        characterClass: ClassRule,
        catalog: RulesCatalog
    ) throws {
        let backgroundSkills = Set(catalog.background(id: character.backgroundID)?.grantedSkillIDs ?? [])
        let classSkills = Set(character.selectedSkillIDs).subtracting(backgroundSkills)
        guard classSkills.isSubset(of: Set(characterClass.availableSkillIDs)),
              backgroundSkills.isSubset(of: Set(character.selectedSkillIDs)),
              classSkills.count == characterClass.skillChoiceCount else {
            throw CharacterValidationError.invalidSkillCount(
                expected: characterClass.skillChoiceCount,
                actual: classSkills.count
            )
        }
    }

    private func validateEquipment(
        _ character: CharacterDocument,
        characterClass: ClassRule,
        catalog: RulesCatalog
    ) throws {
        let hasEquipment = !character.selectedEquipmentIDs.isEmpty
            || character.startingWealthGP != nil
            || character.currencyBalance != nil
        guard hasEquipment else {
            throw CharacterValidationError.invalidEquipment
        }
        let selectedEquipment = Set(character.selectedEquipmentIDs)
        let backgroundEquipment = Set(catalog.background(id: character.backgroundID)?.grantedEquipmentIDs ?? [])
        let allowedEquipment = Set(characterClass.equipmentChoiceGroups.flatMap { $0 }).union(backgroundEquipment)
        guard selectedEquipment.isSubset(of: allowedEquipment) else {
            throw CharacterValidationError.invalidEquipment
        }
        if character.currencyBalance == nil && character.startingWealthGP == nil {
            guard characterClass.equipmentChoiceGroups.allSatisfy({ group in
                !Set(group).isDisjoint(with: selectedEquipment)
            }) else {
                throw CharacterValidationError.invalidEquipment
            }
        }
    }

    private func validateSpells(
        _ character: CharacterDocument,
        characterClass: ClassRule,
        catalog: RulesCatalog
    ) throws {
        let selectedSpellIDs = Set(character.selectedSpellIDs)
        guard selectedSpellIDs.count == character.selectedSpellIDs.count else {
            throw CharacterValidationError.duplicateSpellSelection
        }
        let cantripCount = character.selectedSpellIDs.filter { id in
            catalog.spells.first { $0.id == id }?.level == 0
        }.count
        let leveledCount = character.selectedSpellIDs.count - cantripCount
        guard cantripCount <= characterClass.cantripsKnown,
              leveledCount <= characterClass.spellsKnownOrPrepared else {
            throw CharacterValidationError.spellCountExceeded(
                cantrips: cantripCount,
                leveled: leveledCount
            )
        }
        for spellID in character.selectedSpellIDs {
            let spell = catalog.spells.first { $0.id == spellID }
            guard let spell,
                  spell.classIDs.contains(characterClass.id), spell.level <= 1 else {
                throw CharacterValidationError.invalidSpell(spell?.name ?? spellID)
            }
        }
    }
}
