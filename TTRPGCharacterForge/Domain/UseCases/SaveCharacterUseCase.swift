//
//  SaveCharacterUseCase.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

/// Validates and persists a character document.
struct SaveCharacterUseCase {
    private let repository: CharacterRepository
    
    init(repository: CharacterRepository) {
        self.repository = repository
    }
    
    func saveCharacter(_ character: CharacterDocument) async throws {
        try await repository.save(character)
    }
}
