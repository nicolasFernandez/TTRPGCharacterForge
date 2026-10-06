//
//  LoadCharactersUseCase.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

/// Retrieves the user's saved characters.
struct LoadCharactersUseCase {
    private let repository: CharacterRepository

    init(repository: CharacterRepository) {
        self.repository = repository
    }

    func getCharacterCollection() async throws -> CharacterCollection {
        try await repository.fetchCollection()
    }

    func getAllCharacters() async throws -> [CharacterDocument] {
        try await repository.fetchAll()
    }

    func getCharacter(withID id: UUID) async throws -> CharacterDocument {
        try await repository.fetch(withID: id)
    }

    func duplicate(_ character: CharacterDocument) async throws -> CharacterDocument {
        try await repository.duplicate(character)
    }

    func delete(withID id: UUID) async throws {
        try await repository.delete(withID: id)
    }
}
