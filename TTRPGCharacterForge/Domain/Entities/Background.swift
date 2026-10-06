//
//  Background.swift
//  TTRPGCharacterForge
//
//  Created by Nicolas Alonso Fernandez Alarcon on 13-01-23.
//


// Trasfondo
struct Background {
    let name: String = ""
    let feature: Feat = .none
    let proficiencies: [Skill]? = nil // max two

    // Opening introduction about the background
    let introduction: String = ""

    let personalityTraits: [String] = [] // max two
    let ideal: String = ""
    let bond: String = ""
    let flaw: String = ""

    // Describes what tools proficiencies the background grants
    let toolProficienciesDescription: [String]? = nil // max two

    // Describes what languages the background grants
    let languages: [LanguageType] = [] // max two
}
