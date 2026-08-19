//
//  SpellRepository.swift
//  TTRPGCharacterForge
//
//  Created on 2025-10-13.
//

import Foundation

// Repository protocol defining data operations
/// Provides the spell collection used by the spell browser.
protocol SpellRepository {
    func fetchAllSpells(completion: @escaping (Result<[Spell], Error>) -> Void)
    func fetchSpell(withID id: UUID, completion: @escaping (Result<Spell, Error>) -> Void)
    func fetchSpells(forClass classType: ClassType, completion: @escaping (Result<[Spell], Error>) -> Void)
    func fetchSpells(forLevel level: Int, completion: @escaping (Result<[Spell], Error>) -> Void)
    func searchSpells(byName name: String, completion: @escaping (Result<[Spell], Error>) -> Void)
    func saveSpell(_ spell: Spell, completion: @escaping (Result<Void, Error>) -> Void)
}
