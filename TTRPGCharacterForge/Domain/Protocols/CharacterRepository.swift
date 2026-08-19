//
//  CharacterRepository.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

@MainActor
/// Defines persistence operations for character documents.
protocol CharacterRepository {
    func fetchAll() async throws -> [CharacterDocument]
    func fetch(withID id: UUID) async throws -> CharacterDocument
    func save(_ character: CharacterDocument) async throws
    func duplicate(_ character: CharacterDocument) async throws -> CharacterDocument
    func delete(withID id: UUID) async throws
}
