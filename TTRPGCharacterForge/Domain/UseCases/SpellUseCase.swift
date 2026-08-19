//
//  SpellUseCase.swift
//  TTRPGCharacterForge
//
//  Created on 2025-10-13.
//

import Foundation

// Implementation of the use case
/// Retrieves spells and applies spell-browser filtering rules.
struct SpellUseCase {
    private let repository: SpellRepository
    
    init(repository: SpellRepository) {
        self.repository = repository
    }
    
    func getAllSpells(completion: @escaping (Result<[Spell], Error>) -> Void) {
        repository.fetchAllSpells(completion: completion)
    }
    
    func getSpell(withID id: UUID, completion: @escaping (Result<Spell, Error>) -> Void) {
        repository.fetchSpell(withID: id, completion: completion)
    }
    
    func getSpellsForClass(_ classType: ClassType, completion: @escaping (Result<[Spell], Error>) -> Void) {
        repository.fetchSpells(forClass: classType, completion: completion)
    }
    
    func getSpellsForLevel(_ level: Int, completion: @escaping (Result<[Spell], Error>) -> Void) {
        repository.fetchSpells(forLevel: level, completion: completion)
    }
    
    func searchSpells(byName name: String, completion: @escaping (Result<[Spell], Error>) -> Void) {
        repository.searchSpells(byName: name, completion: completion)
    }
    
    func saveNewSpell(_ spell: Spell, completion: @escaping (Result<Void, Error>) -> Void) {
        repository.saveSpell(spell, completion: completion)
    }
}
