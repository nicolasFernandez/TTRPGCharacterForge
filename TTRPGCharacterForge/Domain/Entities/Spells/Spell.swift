//
//  Spell.swift
//  TTRPGCharacterForge
//
//  Created on 2025-10-13.
//

import Foundation

// Entity with properties representing D&D spells
struct Spell: Identifiable {
    let id: UUID
    let stableID: String?
    let name: String
    let level: Int
    let school: SpellSchool
    let castingTime: String
    let range: String
    let components: SpellComponents
    let duration: String
    let levelDescription: String
    let higherLevelsDescription: String?
    let classes: [ClassType]
    
    var isRitual: Bool = false
    var requiresConcentration: Bool = false

    init(
        id: UUID = UUID(),
        stableID: String? = nil,
        name: String,
        level: Int,
        school: SpellSchool,
        castingTime: String,
        range: String,
        components: SpellComponents,
        duration: String,
        levelDescription: String,
        higherLevelsDescription: String?,
        classes: [ClassType],
        isRitual: Bool = false,
        requiresConcentration: Bool = false
    ) {
        self.id = id
        self.stableID = stableID
        self.name = name
        self.level = level
        self.school = school
        self.castingTime = castingTime
        self.range = range
        self.components = components
        self.duration = duration
        self.levelDescription = levelDescription
        self.higherLevelsDescription = higherLevelsDescription
        self.classes = classes
        self.isRitual = isRitual
        self.requiresConcentration = requiresConcentration
    }
     
    var levelString: String {
        if level == 0 {
            return NSLocalizedString("cantrip_text", comment: "")
        } else {
            return String(format: NSLocalizedString("level_text", comment: ""), level)
        }
    }
}

extension Spell: Equatable {
    static func == (lhs: Spell, rhs: Spell) -> Bool {
        return lhs.id == rhs.id
    }
}
