//
//  SaveCharacterUseCase.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

/// Persists a character document. Validation is performed by the completion use case.
struct SaveCharacterUseCase {
    private let repository: CharacterRepository

    init(repository: CharacterRepository) {
        self.repository = repository
    }

    func saveCharacter(_ character: CharacterDocument) async throws {
        try await repository.save(character)
    }
}
