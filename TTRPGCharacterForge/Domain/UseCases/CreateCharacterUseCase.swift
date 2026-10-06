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
        try validateLanguages(character, race: race, catalog: catalog)
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
        let selectedSkills = Set(character.selectedSkillIDs)
        let classSkills = selectedSkills.subtracting(backgroundSkills)
        guard selectedSkills.count == character.selectedSkillIDs.count,
              classSkills.isSubset(of: Set(characterClass.availableSkillIDs)),
              backgroundSkills.isSubset(of: selectedSkills),
              classSkills.count == characterClass.skillChoiceCount else {
            throw CharacterValidationError.invalidSkillCount(
                expected: characterClass.skillChoiceCount,
                actual: classSkills.count
            )
        }
    }

    private func validateLanguages(_ character: CharacterDocument, race: RaceRule, catalog: RulesCatalog) throws {
        guard let background = catalog.background(id: character.backgroundID) else {
            throw CharacterValidationError.missingRequiredChoice("background")
        }
        let granted = Set(race.grantedLanguageIDs + background.grantedLanguageIDs)
        let selected = Set(character.selectedLanguageIDs)
        let additionalCount = race.additionalLanguageChoices + background.additionalLanguageChoices
        guard granted.isSubset(of: selected),
              selected.isSubset(of: Set(catalog.languages.map(\.id))),
              selected.count == character.selectedLanguageIDs.count,
              selected.subtracting(granted).count == additionalCount else {
            throw CharacterValidationError.missingRequiredChoice("languages")
        }
    }

    private func validateEquipment(
        _ character: CharacterDocument,
        characterClass: ClassRule,
        catalog: RulesCatalog
    ) throws {
        let selected = Set(character.selectedEquipmentIDs)
        let background = Set(catalog.background(id: character.backgroundID)?.grantedEquipmentIDs ?? [])
        let allowed = Set(characterClass.equipmentChoiceGroups.flatMap { $0 }).union(background)
        guard selected.isSubset(of: allowed), background.isSubset(of: selected) else {
            throw CharacterValidationError.invalidEquipment
        }
        if try hasPositiveWealth(character) { return }
        guard !selected.isEmpty,
              characterClass.equipmentChoiceGroups.allSatisfy({ !Set($0).isDisjoint(with: selected) }) else {
            throw CharacterValidationError.invalidEquipment
        }
    }

    private func hasPositiveWealth(_ character: CharacterDocument) throws -> Bool {
        if let balance = character.currencyBalance {
            return try hasPositiveBalance(balance)
        }
        if let wealth = character.startingWealthGP {
            guard wealth >= 0 else { throw CharacterValidationError.invalidEquipment }
            return wealth > 0
        }
        return false
    }

    private func hasPositiveBalance(_ balance: CurrencyBalance) throws -> Bool {
        let counts = [balance.copper, balance.silver, balance.electrum, balance.gold, balance.platinum]
        guard counts.allSatisfy({ $0 >= 0 }) else { throw CharacterValidationError.invalidEquipment }
        return counts.contains { $0 > 0 }
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
            try validateSpell(spellID, classID: characterClass.id, catalog: catalog)
        }
    }

    private func validateSpell(_ id: String, classID: String, catalog: RulesCatalog) throws {
        let spell = catalog.spells.first { $0.id == id }
        guard let spell, spell.classIDs.contains(classID), spell.level <= 1 else {
            throw CharacterValidationError.invalidSpell(spell?.name ?? id)
        }
    }
}
