//
//  Skill.swift
//  TTRPGCharacterForge
//
//  Created by Nicolas Alonso Fernandez Alarcon on 13-01-23.
//


/// Defines a skill of the character like acrobatics, animal handling...
struct Skill {
    let name: String
    private let baseAbility: Ability
    private let proficiencyBonus: Int

    var modifier: Int {
        return baseAbility.modifier + self.proficiencyBonus
    }

    init(name: String, baseAbility: Ability, proficiencyBonus: Int = 0, modifier: Int) {
        self.name = name
        self.baseAbility = baseAbility
        self.proficiencyBonus = proficiencyBonus
    }
}
