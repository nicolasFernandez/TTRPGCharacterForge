//
//  CharacterRecord.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation
import SwiftData

/// SwiftData record used to persist an encoded character document.
@Model
final class CharacterRecord {
    @Attribute(.unique)
    var id: UUID
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
        let encoded = try encoder.encode(document)
        name = document.name
        classID = document.classID
        stateValue = document.state.rawValue
        updatedAt = document.updatedAt
        payload = encoded
    }
}

/// Describes failures while reading or decoding persisted characters.
enum CharacterStoreError: LocalizedError {
    case notFound(UUID)
    case unsupportedSchema(Int)
    case unsupportedRuleset(String)
    case corrupted(UUID, Error)

    var errorDescription: String? {
        switch self {
        case .notFound:
            NSLocalizedString("character_store_not_found", comment: "Character persistence record was not found")
        case .unsupportedSchema:
            NSLocalizedString(
                "character_store_unsupported_schema",
                comment: "Character persistence schema is unsupported"
            )
        case .unsupportedRuleset:
            NSLocalizedString("character_store_unsupported_ruleset", comment: "Character ruleset is unsupported")
        case .corrupted:
            NSLocalizedString("character_store_corrupted", comment: "Character persistence record is corrupted")
        }
    }
}

/// Local-only repository. The historical filename is retained to avoid a risky Xcode
/// project-file migration; no Firestore APIs are used.
/// Stores character documents in the app's SwiftData model container.
final class SwiftDataCharacterRepository: CharacterRepository {
    let store: Task<CharacterStoreActor, Never>
    private static let creationQueue = DispatchQueue(label: "character-store.creation")

    init(container: ModelContainer, portraitStore: PortraitStore) {
        // SwiftData chooses its context queue during initialization. An explicit
        // background queue prevents construction on the main thread.
        store = Task.detached {
            await withCheckedContinuation { continuation in
                Self.creationQueue.async {
                    continuation.resume(returning: CharacterStoreActor(
                        container: container,
                        portraitStore: portraitStore
                    ))
                }
            }
        }
    }

    func fetchAll() async throws -> [CharacterDocument] {
        try await store.value.fetchAll()
    }

    func fetchCollection() async throws -> CharacterCollection {
        try await store.value.fetchCollection()
    }

    func fetch(withID id: UUID) async throws -> CharacterDocument {
        try await store.value.fetch(withID: id)
    }

    func save(_ character: CharacterDocument) async throws {
        try await store.value.save(character)
    }

    func duplicate(_ character: CharacterDocument) async throws -> CharacterDocument {
        try await store.value.duplicate(character)
    }

    func delete(withID id: UUID) async throws {
        try await store.value.delete(withID: id)
    }
}

actor CharacterStoreActor: ModelActor {
    private nonisolated let serialExecutor: DefaultSerialModelExecutor

    nonisolated var modelExecutor: any ModelExecutor { serialExecutor }
    nonisolated let modelContainer: ModelContainer

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        serialExecutor.asUnownedSerialExecutor()
    }
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let legacyDecoder: JSONDecoder
    private let portraitStore: PortraitStore

    init(container: ModelContainer, portraitStore: PortraitStore) {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        modelContainer = container
        serialExecutor = DefaultSerialModelExecutor(modelContext: context)
        self.portraitStore = portraitStore
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        legacyDecoder = JSONDecoder()
        legacyDecoder.dateDecodingStrategy = .secondsSince1970
    }

    func fetchAll() throws -> [CharacterDocument] {
        let collection = try fetchCollection()
        // Legacy callers cannot display unreadable metadata; preserve an explicit
        // failure instead of silently returning a partial collection.
        if let unreadable = collection.unreadableRecords.first { throw unreadable.error }
        return collection.characters
    }

    func fetchCollection() throws -> CharacterCollection {
        let descriptor = FetchDescriptor<CharacterRecord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        var characters: [CharacterDocument] = []
        var unreadable: [UnreadableCharacterRecord] = []
        for record in try modelContext.fetch(descriptor) {
            do {
                characters.append(try decode(record))
            } catch {
                unreadable.append(UnreadableCharacterRecord(id: record.id, name: record.name, error: error))
            }
        }
        return CharacterCollection(characters: characters, unreadableRecords: unreadable)
    }

    func fetch(withID id: UUID) throws -> CharacterDocument {
        guard let record = try record(withID: id) else { throw CharacterStoreError.notFound(id) }
        return try decode(record)
    }

    func save(_ character: CharacterDocument) throws {
        try validateCurrency(character.currencyBalance)
        var value = character
        value.updatedAt = Date()
        if let existing = try record(withID: value.id) {
            try existing.update(from: value, encoder: encoder)
        } else {
            modelContext.insert(try CharacterRecord(document: value, encoder: encoder))
        }
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func duplicate(_ character: CharacterDocument) throws -> CharacterDocument {
        var copy = character
        copy.id = UUID()
        let suffix = NSLocalizedString(
            "character_duplicate_suffix",
            comment: "Suffix added to duplicated character names"
        )
        copy.name = character.name.isEmpty ? suffix : "\(character.name) \(suffix)"
        copy.state = .draft
        copy.createdAt = Date()
        copy.updatedAt = copy.createdAt
        copy.currentStep = .review
        copy.portrait = try portraitStore.duplicate(character.portrait, for: copy.id)
        do {
            try save(copy)
        } catch {
            if let portrait = copy.portrait { try? portraitStore.delete(portrait) }
            throw error
        }
        return copy
    }

    func delete(withID id: UUID) throws {
        guard let existing = try record(withID: id) else { return }
        let document = try? decode(existing)
        modelContext.delete(existing)
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
        if let portrait = document?.portrait {
            try? portraitStore.delete(portrait)
        }
    }

    private func record(withID id: UUID) throws -> CharacterRecord? {
        var descriptor = FetchDescriptor<CharacterRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func decode(_ record: CharacterRecord) throws -> CharacterDocument {
        do {
            let document: CharacterDocument
            do {
                document = try decoder.decode(CharacterDocument.self, from: record.payload)
            } catch {
                document = try legacyDecoder.decode(CharacterDocument.self, from: record.payload)
            }
            try validateDocument(document)
            return document
        } catch let error as CharacterStoreError {
            throw error
        } catch {
            throw CharacterStoreError.corrupted(record.id, error)
        }
    }

    private func validateDocument(_ document: CharacterDocument) throws {
        guard document.schemaVersion == CharacterDocument.currentSchemaVersion else {
            throw CharacterStoreError.unsupportedSchema(document.schemaVersion)
        }
        guard document.rulesetID == CharacterDocument.rulesetID else {
            throw CharacterStoreError.unsupportedRuleset(document.rulesetID)
        }
        try validateCurrency(document.currencyBalance)
    }

    private func validateCurrency(_ balance: CurrencyBalance?) throws {
        guard let balance else { return }
        _ = try ConvertCurrencyUseCase().execute(.init(
            copper: String(balance.copper),
            silver: String(balance.silver),
            electrum: String(balance.electrum),
            gold: String(balance.gold),
            platinum: String(balance.platinum)
        ))
    }
}
