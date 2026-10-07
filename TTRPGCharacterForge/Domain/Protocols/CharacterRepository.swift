//
//  CharacterRepository.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

/// Defines persistence operations for character documents.
protocol CharacterRepository {
    func fetchCollection() async throws -> CharacterCollection
    func fetchAll() async throws -> [CharacterDocument]
    func fetch(withID id: UUID) async throws -> CharacterDocument
    func save(_ character: CharacterDocument) async throws
    func duplicate(_ character: CharacterDocument) async throws -> CharacterDocument
    func delete(withID id: UUID) async throws
}

/// Records that remain stored but cannot currently be opened.
struct UnreadableCharacterRecord: Identifiable {
    let id: UUID
    let name: String
    let error: Error
}

struct CharacterCollection {
    let characters: [CharacterDocument]
    let unreadableRecords: [UnreadableCharacterRecord]
}

extension CharacterRepository {
    func fetchCollection() async throws -> CharacterCollection {
        CharacterCollection(characters: try await fetchAll(), unreadableRecords: [])
    }
}
