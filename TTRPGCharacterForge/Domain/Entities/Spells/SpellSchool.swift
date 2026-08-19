//
//  SpellSchool.swift
//  TTRPGCharacterForge
//
//  Created by Nicolas Alonso Fernandez Alarcon on 13-10-25.
//

import Foundation

enum SpellSchool: String, CaseIterable {
    case abjuration
    case conjuration
    case divination
    case enchantment
    case evocation
    case illusion
    case necromancy
    case transmutation

    var name: String {
        NSLocalizedString("spell_school_\(self.rawValue)", comment: "")
    }
}
