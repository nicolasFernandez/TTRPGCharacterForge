//
//  DamageType.swift
//  TTRPGCharacterForge
//
//  Created by Nicolas Alonso Fernandez Alarcon on 26-12-22.
//

import Foundation

enum DamageType: String, Codable, Sendable {
    case acid
    case bludgeoning
    case cold
    case fire
    case force
    case lightning
    case necrotic
    case piercing
    case poison
    case psychic
    case radiant
    case slashing
    case thunder

    var name: String {
        NSLocalizedString("\(self.rawValue.camelToSnakeCase())_name", comment: "")
    }
}
