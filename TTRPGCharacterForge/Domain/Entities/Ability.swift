//
//  Ability.swift
//  TTRPGCharacterForge
//
//  Created by Nicolas Alonso Fernandez Alarcon on 26-12-22.
//


/// Represents abilities of the character 
/// Strength, Dexterity, Constitution, Intelligence, Wisdom, Charisma
struct Ability {
    private let base: Int
    private let raceBonus: Int

    var modifier: Int {
        let finalModifier = ((Float(totalScore)) - 10) / 2
        return Int(finalModifier.rounded(.down))
    }

    var totalScore: Int {
        base + raceBonus
    }

    init(base: Int, raceBonus: Int = 0) {
        self.base = base
        self.raceBonus = raceBonus
    }
}
