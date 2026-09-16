//
//  BackgroundType.swift
//  TTRPGCharacterForge
//
//  Created by Nicolas Alonso Fernandez Alarcon on 27-12-22.
//

import Foundation

enum BackgroundType: String {
    case acolyte

    var name: String {
        NSLocalizedString("\(self.rawValue.camelToSnakeCase())_name", comment: "")
    }

    var description: String {
        NSLocalizedString("\(self.rawValue.camelToSnakeCase())_description", comment: "")
    }

    var skillProficiencies: String? { nil } // TODO: add a way to set proficiencies on skills
    var languages: String? { nil }
    var personalityTraits: String? { nil }
    var ideals: String? { nil }
    var bonds: String? { nil }
    var flaws: String? { nil }
}
