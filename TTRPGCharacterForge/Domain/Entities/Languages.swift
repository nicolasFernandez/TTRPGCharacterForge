//
//  Languages.swift
//  TTRPGCharacterForge
//
//  Created by Nicolas Alonso Fernandez Alarcon on 27-12-22.
//

import Foundation

enum LanguageType: String {
    case common
    case dwarvish
    case elvish
    case giant
    case gnomish
    case goblin
    case halfling
    case orc
    case abyssal
    case celestial
    case draconic
    case deepSpeech
    case infernal
    case primordial
    case sylvan
    case undercommon

    var name: String {
        NSLocalizedString("\(self.rawValue.camelToSnakeCase())_name", comment: "")
    }

    var typicalSpeakers: [String] {
        switch self {
        case .common: return ["Humans"]
        case .dwarvish: return ["Dwarves"]
        case .elvish: return ["Elves"]
        case .giant: return ["Ogres", "Giants"]
        case .gnomish: return ["Gnomes"]
        case .goblin: return ["Goblinoids"]
        case .halfling: return ["Halflings"]
        case .orc: return ["Orcs"]
        case .abyssal: return ["Demons"]
        case .celestial: return ["Celestials"]
        case .draconic: return ["Dragons", "Dragonborns"]
        case .deepSpeech: return ["Aboleths", "Cloakers"]
        case .infernal: return ["Devils"]
        case .primordial: return ["Elementals"]
        case .sylvan: return ["Fey creatures"]
        case .undercommon: return ["Underworld traders"]
        }
    }

    var script: LanguageScript {
        switch self {
        case .common, .halfling:
            return LanguageScript.common
        case .dwarvish, .giant, .gnomish, .goblin, .orc, .primordial:
            return LanguageScript.dwarvish
        case .elvish, .sylvan, .undercommon:
            return LanguageScript.elvish
        case .abyssal, .infernal:
            return LanguageScript.infernal
        case .celestial:
            return LanguageScript.celestial
        case .draconic:
            return LanguageScript.draconic
        case .deepSpeech:
            return LanguageScript.none
        }
    }
}

enum LanguageScript: String {
    case common
    case dwarvish
    case elvish
    case infernal
    case celestial
    case draconic
    case none
}
