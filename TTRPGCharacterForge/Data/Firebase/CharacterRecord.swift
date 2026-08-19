//
//  CharacterRecord.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation
import SwiftData

@Model
/// SwiftData record used to persist an encoded character document.
final class CharacterRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var classID: String?
    var stateValue: String
    var updatedAt: Date
    var payload: Data

    init(document: CharacterDocument, encoder: JSONEncoder = JSONEncoder()) throws {
        id = document.id
        name = document.name
        classID = document.classID
        stateValue = document.state.rawValue
        updatedAt = document.updatedAt
        payload = try encoder.encode(document)
    }

    func update(from document: CharacterDocument, encoder: JSONEncoder) throws {
        name = document.name
        classID = document.classID
        stateValue = document.state.rawValue
        updatedAt = document.updatedAt
        payload = try encoder.encode(document)
    }
}

/// Describes failures while reading or decoding persisted characters.
enum CharacterStoreError: LocalizedError {
    case notFound(UUID)
    case unsupportedSchema(Int)
    case corrupted(UUID, Error)

    var errorDescription: String? {
        switch self {
        case .notFound(let id): "Character \(id) was not found."
        case .unsupportedSchema(let version): "Character schema \(version) is not supported."
        case .corrupted(let id, _): "Character \(id) could not be decoded."
        }
    }
}

/// Local-only repository. The historical filename is retained to avoid a risky Xcode
/// project-file migration; no Firestore APIs are used.
@MainActor
/// Stores character documents in the app's SwiftData model container.
final class SwiftDataCharacterRepository: CharacterRepository {
    private let context: ModelContext
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let portraitStore: PortraitStore

    init(context: ModelContext, portraitStore: PortraitStore) {
        self.context = context
        self.portraitStore = portraitStore
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func fetchAll() async throws -> [CharacterDocument] {
        let descriptor = FetchDescriptor<CharacterRecord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map(decode)
    }

    func fetch(withID id: UUID) async throws -> CharacterDocument {
        guard let record = try record(withID: id) else { throw CharacterStoreError.notFound(id) }
        return try decode(record)
    }

    func save(_ character: CharacterDocument) async throws {
        var value = character
        value.updatedAt = Date()
        if let existing = try record(withID: value.id) {
            try existing.update(from: value, encoder: encoder)
        } else {
            context.insert(try CharacterRecord(document: value, encoder: encoder))
        }
        try context.save()
    }

    func duplicate(_ character: CharacterDocument) async throws -> CharacterDocument {
        var copy = character
        copy.id = UUID()
        copy.name = character.name.isEmpty ? "Copy" : "\(character.name) Copy"
        copy.state = .draft
        copy.createdAt = Date()
        copy.updatedAt = copy.createdAt
        copy.currentStep = .review
        copy.portrait = try portraitStore.duplicate(character.portrait, for: copy.id)
        try await save(copy)
        return copy
    }

    func delete(withID id: UUID) async throws {
        guard let existing = try record(withID: id) else { return }
        let document = try? decode(existing)
        context.delete(existing)
        try context.save()
        if let portrait = document?.portrait {
            try portraitStore.delete(portrait)
        }
    }

    private func record(withID id: UUID) throws -> CharacterRecord? {
        var descriptor = FetchDescriptor<CharacterRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func decode(_ record: CharacterRecord) throws -> CharacterDocument {
        do {
            let document = try decoder.decode(CharacterDocument.self, from: record.payload)
            guard document.schemaVersion == CharacterDocument.currentSchemaVersion else {
                throw CharacterStoreError.unsupportedSchema(document.schemaVersion)
            }
            return document
        } catch let error as CharacterStoreError {
            throw error
        } catch {
            throw CharacterStoreError.corrupted(record.id, error)
        }
    }
}
