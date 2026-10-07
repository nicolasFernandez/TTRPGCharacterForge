//
//  TTRPGCharacterForgeTests.swift
//  TTRPGCharacterForgeTests
//
//  Created by Nicolas Alonso Fernandez Alarcon on 26-12-22.
//

import XCTest
import SwiftData
@testable import TTRPGCharacterForge

final class TTRPGCharacterForgeTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testStandardArrayValidation() {
        let scores = AbilityScoreSet(strength: 15, dexterity: 14, constitution: 13, intelligence: 12, wisdom: 10, charisma: 8)
        XCTAssertTrue(AbilityAssignmentService().validate(scores, method: .standardArray))
        var invalid = scores
        invalid.charisma = 9
        XCTAssertFalse(AbilityAssignmentService().validate(invalid, method: .standardArray))
    }

    func testPointBuyRequiresExactlyTwentySevenPoints() {
        let valid = AbilityScoreSet(strength: 15, dexterity: 15, constitution: 15, intelligence: 8, wisdom: 8, charisma: 8)
        XCTAssertTrue(AbilityAssignmentService().validate(valid, method: .pointBuy))
        var invalid = valid
        invalid.strength = 14
        XCTAssertFalse(AbilityAssignmentService().validate(invalid, method: .pointBuy))
    }

    func testRolledScoresDropLowestDie() {
        let generator = FixedRandomNumberGenerator(values: [1, 6, 5, 4])
        let rolls = AbilityAssignmentService().rollSet(using: generator)
        XCTAssertEqual(rolls, Array(repeating: 15, count: 6))
    }

    func testAbilityModifierRoundsNegativeValuesDown() {
        XCTAssertEqual(ComputeDerivedStatsUseCase.modifier(for: 9), -1)
        XCTAssertEqual(ComputeDerivedStatsUseCase.modifier(for: 7), -2)
        XCTAssertEqual(ComputeDerivedStatsUseCase.modifier(for: 10), 0)
        XCTAssertEqual(ComputeDerivedStatsUseCase.modifier(for: 18), 4)
    }

    func testCharacterDocumentRoundTripsThroughJSON() throws {
        var character = CharacterDocument(name: "Mira")
        character.raceID = "human"
        character.classID = "wizard"
        let data = try JSONEncoder().encode(character)
        XCTAssertEqual(try JSONDecoder().decode(CharacterDocument.self, from: data), character)
    }

}

private final class FixedRandomNumberGenerator: RandomNumberGenerating {
    private let values: [Int]
    private var index = 0

    init(values: [Int]) { self.values = values }

    func next(in range: ClosedRange<Int>) -> Int {
        defer { index += 1 }
        return values[index % values.count]
    }
}

/// UT-PR115: regression coverage for review findings about draft persistence.
@MainActor
final class CharacterPersistenceReviewTests: XCTestCase {
    func testDirectBoundEditPersistsWithoutNavigation() async throws {
        let repository = ReviewCharacterRepository()
        let saved = expectation(description: "Bound edit autosaves")
        repository.didSave = { saved.fulfill() }
        let editor = makeEditor(repository)
        editor.character.name = "Bound name"
        await fulfillment(of: [saved], timeout: 2)
        XCTAssertEqual(repository.documents.last?.name, "Bound name")
    }

    func testFlushWaitsForCancelledInFlightSaveAndPreservesLatestEdit() async throws {
        let repository = ReviewCharacterRepository()
        repository.holdFirstSave = true
        let started = expectation(description: "Earlier writer entered repository")
        repository.didStart = { started.fulfill() }
        let editor = makeEditor(repository)
        editor.character.name = "Earlier"
        await fulfillment(of: [started], timeout: 2)
        editor.character.name = "Latest"
        let flush = Task { await editor.flushAutosave() }
        await Task.yield()
        XCTAssertEqual(repository.startedCount, 1)
        repository.releaseFirstSave()
        let success = await flush.value
        XCTAssertTrue(success)
        XCTAssertEqual(repository.documents.map(\.name), ["Earlier", "Latest"])
        XCTAssertEqual(repository.maximumConcurrentSaves, 1)
    }

    func testInvalidCompletionKeepsPendingDraftSave() async {
        let repository = ReviewCharacterRepository()
        let saved = expectation(description: "Invalid draft remains saved")
        repository.didSave = { saved.fulfill() }
        let editor = makeEditor(repository)
        editor.character.name = "Incomplete"
        let completed = await editor.complete()
        XCTAssertFalse(completed)
        await fulfillment(of: [saved], timeout: 2)
        XCTAssertEqual(repository.documents.last?.name, "Incomplete")
        XCTAssertEqual(repository.documents.last?.state, .draft)
    }

    func testFailedPortraitPersistencePreservesOldFileAndRemovesReplacement() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = PortraitStore(baseURL: directory)
        let repository = ReviewCharacterRepository()
        repository.failSaves = true
        let oldData = Data("original portrait".utf8)
        let original = try store.save(oldData, for: UUID())
        let editor = makeEditor(repository, portraitStore: store,
                                character: CharacterDocument(portrait: original))
        await editor.importPortrait(Data("replacement portrait".utf8))
        XCTAssertEqual(editor.character.portrait, original)
        XCTAssertEqual(try Data(contentsOf: store.url(for: original)), oldData)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path),
                       [original.relativePath])
        XCTAssertNotNil(editor.errorMessage)
    }

    func testSuccessfulPortraitReplacementIsPersistedBeforeOldFileRemoval() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = PortraitStore(baseURL: directory)
        let repository = ReviewCharacterRepository()
        let original = try store.save(Data("original portrait".utf8), for: UUID())
        let oldURL = try store.url(for: original)
        repository.didSave = { XCTAssertTrue(FileManager.default.fileExists(atPath: oldURL.path)) }
        let editor = makeEditor(repository, portraitStore: store,
                                character: CharacterDocument(portrait: original))
        let newData = Data("replacement portrait".utf8)
        await editor.importPortrait(newData)
        let replacement = try XCTUnwrap(editor.character.portrait)
        XCTAssertNotEqual(replacement.relativePath, original.relativePath)
        XCTAssertEqual(repository.documents.last?.portrait, replacement)
        XCTAssertEqual(try Data(contentsOf: store.url(for: replacement)), newData)
        XCTAssertFalse(FileManager.default.fileExists(atPath: oldURL.path))
        XCTAssertNil(editor.errorMessage)
    }

    func testSuspendedCurrencySavePreservesNewerEditorEdits() async throws {
        let repository = ReviewCharacterRepository()
        repository.holdFirstSave = true
        let started = expectation(description: "Currency save suspended")
        repository.didStart = { started.fulfill() }
        let editor = makeEditor(repository)
        let saving = Task { try await editor.saveCurrencyBalance(.init(gold: 7)) }
        await fulfillment(of: [started], timeout: 2)
        XCTAssertTrue(editor.isLoading)
        editor.character.name = "Newer edit"
        repository.releaseFirstSave()
        try await saving.value
        XCTAssertFalse(editor.isLoading)
        XCTAssertEqual(editor.character.name, "Newer edit")
        XCTAssertEqual(editor.character.currencyBalance, .init(gold: 7))
        let flushed = await editor.flushAutosave()
        XCTAssertTrue(flushed)
        XCTAssertEqual(repository.documents.last?.name, "Newer edit")
        XCTAssertEqual(repository.documents.last?.currencyBalance, .init(gold: 7))
    }

    func testDraftSaveSurvivesEditorRelease() async {
        let repository = ReviewCharacterRepository()
        let saved = expectation(description: "Save dependency survives editor")
        repository.didSave = { saved.fulfill() }
        var editor: CharacterEditorVM? = makeEditor(repository)
        editor?.character.name = "Released editor"
        editor = nil
        await fulfillment(of: [saved], timeout: 2)
        XCTAssertEqual(repository.documents.last?.name, "Released editor")
    }

    func testNegativeCurrencyIsRejectedBeforePersistence() async {
        let repository = ReviewCharacterRepository()
        let editor = makeEditor(repository)
        do {
            try await editor.saveCurrencyBalance(.init(gold: -1))
            XCTFail("Expected negative balance rejection")
        } catch {
            XCTAssertEqual(error as? ConvertCurrencyUseCase.ConversionError, .invalidCoinCount)
        }
        XCTAssertTrue(repository.documents.isEmpty)
        XCTAssertNil(editor.character.currencyBalance)
    }

    func testFailedFlushKeepsEditorAvailableAndReportsFailure() async {
        let repository = ReviewCharacterRepository()
        repository.failSaves = true
        let editor = makeEditor(repository)
        editor.character.name = "Unsaved"
        let success = await editor.flushAutosave()
        XCTAssertFalse(success)
        XCTAssertEqual(editor.character.name, "Unsaved")
        XCTAssertNotNil(editor.errorMessage)
    }

    func testCancelledListLoadResetsLoadingState() async {
        let repository = ReviewCharacterRepository()
        repository.cancelLoads = true
        let list = CharacterListViewModel(
            loadCharactersUseCase: LoadCharactersUseCase(repository: repository),
            saveCharacterUseCase: SaveCharacterUseCase(repository: repository)
        )
        await list.loadCharacters()
        XCTAssertFalse(list.isLoading)
        XCTAssertNil(list.errorMessage)
    }

    func testClassChangeRetainsAndLocksMandatoryBackgroundSkills() throws {
        let repository = ReviewCharacterRepository()
        let catalog = try BundledRulesRepository().catalog(locale: .english)
        let editor = makeEditor(repository, catalog: catalog)
        editor.character.backgroundID = "acolyte"
        editor.character.classID = "barbarian"
        editor.character.selectedSkillIDs = ["religion", "insight", "arcana", "athletics"]
        editor.reconcileClassSelection()
        XCTAssertEqual(Set(editor.character.selectedSkillIDs), ["religion", "insight", "athletics"])
        editor.toggleSkill("religion")
        XCTAssertTrue(editor.character.selectedSkillIDs.contains("religion"))
    }

    func testRaceAndBackgroundLanguageChoicesKeepMandatoryGrants() throws {
        let repository = ReviewCharacterRepository()
        let catalog = try BundledRulesRepository().catalog(locale: .english)
        let editor = makeEditor(repository, catalog: catalog)
        editor.character.raceID = "human"
        editor.applyRaceBonuses()
        editor.character.backgroundID = "acolyte"
        editor.reconcileBackgroundSelection(previousID: nil)
        XCTAssertEqual(editor.additionalLanguageChoiceCount, 3)
        XCTAssertEqual(editor.grantedLanguageIDs, ["common"])
        editor.toggleLanguage("common")
        XCTAssertTrue(editor.character.selectedLanguageIDs.contains("common"))
        editor.toggleLanguage("draconic")
        XCTAssertTrue(editor.character.selectedLanguageIDs.contains("draconic"))
        editor.character.raceID = "elf"
        editor.applyRaceBonuses(previousID: "human")
        XCTAssertEqual(editor.additionalLanguageChoiceCount, 2)
        XCTAssertTrue(Set(["common", "elvish"]).isSubset(of: Set(editor.character.selectedLanguageIDs)))
    }

    private func makeEditor(
        _ repository: ReviewCharacterRepository,
        catalog: RulesCatalog? = nil,
        portraitStore: PortraitStore = PortraitStore(),
        character: CharacterDocument? = nil
    ) -> CharacterEditorVM {
        CharacterEditorVM(
            createCharacterUseCase: CreateCharacterUseCase(),
            updateAbilityScoreUseCase: UpdateAbilityScoreUseCase(),
            computeDerivedStatsUseCase: ComputeDerivedStatsUseCase(),
            saveCharacterUseCase: SaveCharacterUseCase(repository: repository),
            catalog: catalog ?? RulesCatalog(schemaVersion: 1, rulesetID: CharacterDocument.rulesetID,
                                  locale: "en", races: [], classes: [], backgrounds: [], skills: [],
                                  languages: [], equipment: [], spells: []),
            character: character,
            portraitStore: portraitStore
        )
    }
}

@MainActor
private final class ReviewCharacterRepository: CharacterRepository {
    enum Failure: Error { case save }
    var documents: [CharacterDocument] = []
    var failSaves = false
    var cancelLoads = false
    var holdFirstSave = false
    var didStart: (() -> Void)?
    var didSave: (() -> Void)?
    var startedCount = 0
    var maximumConcurrentSaves = 0
    private var activeSaves = 0
    private var firstSave: CheckedContinuation<Void, Never>?

    func releaseFirstSave() { firstSave?.resume(); firstSave = nil }
    func fetchAll() async throws -> [CharacterDocument] {
        if cancelLoads { throw CancellationError() }
        return documents
    }
    func fetch(withID id: UUID) async throws -> CharacterDocument {
        guard let value = documents.last(where: { $0.id == id }) else {
            throw CharacterStoreError.notFound(id)
        }
        return value
    }
    func save(_ character: CharacterDocument) async throws {
        startedCount += 1
        activeSaves += 1
        maximumConcurrentSaves = max(maximumConcurrentSaves, activeSaves)
        defer { activeSaves -= 1 }
        if holdFirstSave && startedCount == 1 {
            await withCheckedContinuation { continuation in
                firstSave = continuation
                didStart?()
            }
        }
        if failSaves { throw Failure.save }
        documents.append(character)
        didSave?()
    }
    func duplicate(_ character: CharacterDocument) async throws -> CharacterDocument { character }
    func delete(withID id: UUID) async throws { documents.removeAll { $0.id == id } }
}

@MainActor
final class CharacterCorruptionRecoveryTests: XCTestCase {
    // UT-PR115-BACKGROUND-STORE: exercise CRUD through the actor created by main-actor composition.
    func testRepositoryCRUDWhenCreatedOnMainActor() async throws {
        XCTAssertTrue(Thread.isMainThread)
        let container = try ModelContainer(for: CharacterRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let repository = SwiftDataCharacterRepository(container: container, portraitStore: PortraitStore())
        let original = CharacterDocument(name: "Background original")
        try await repository.save(original)
        let copy = try await repository.duplicate(original)
        XCTAssertNotEqual(copy.id, original.id)
        let fetched = try await repository.fetch(withID: original.id)
        XCTAssertEqual(fetched.name, original.name)
        try await repository.delete(withID: copy.id)
        let collection = try await repository.fetchCollection()
        XCTAssertEqual(collection.characters.map(\.id), [original.id])
        XCTAssertTrue(Thread.isMainThread)
    }

    func testConcurrentSavesRemainConsistentOnBackgroundStore() async throws {
        let container = try ModelContainer(for: CharacterRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let repository = SwiftDataCharacterRepository(container: container, portraitStore: PortraitStore())
        let documents = (0..<12).map { CharacterDocument(name: "Concurrent \($0)") }
        try await withThrowingTaskGroup(of: Void.self) { group in
            for document in documents {
                group.addTask { try await repository.save(document) }
            }
            try await group.waitForAll()
        }
        let fetched = try await repository.fetchAll()
        XCTAssertEqual(Set(fetched.map(\.id)), Set(documents.map(\.id)))
        XCTAssertEqual(Set(fetched.map(\.name)), Set(documents.map(\.name)))
    }

    // UT-PR115-OVERFLOW: checked conversion validates persisted totals without changing denominations.
    func testCurrencyOverflowRejectedBeforeUpdatingExistingRecord() async throws {
        let container = try ModelContainer(for: CharacterRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let repository = SwiftDataCharacterRepository(container: container, portraitStore: PortraitStore())
        let original = CharacterDocument(name: "Original", currencyBalance: .zero)
        try await repository.save(original)
        for balance in [CurrencyBalance(gold: Int64.max), CurrencyBalance(copper: Int64.max, silver: 1)] {
            var invalid = original
            invalid.name = "Must not be persisted"
            invalid.currencyBalance = balance
            do {
                try await repository.save(invalid)
                XCTFail("Overflow must be rejected")
            } catch {
                XCTAssertEqual(error as? ConvertCurrencyUseCase.ConversionError, .amountTooLarge)
            }
            let retained = try await repository.fetch(withID: original.id)
            XCTAssertEqual(retained.name, original.name)
            XCTAssertEqual(retained.currencyBalance, original.currencyBalance)
        }
    }

    func testMaximumCurrencyTotalPreservesOriginalDenominations() async throws {
        let container = try ModelContainer(for: CharacterRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let repository = SwiftDataCharacterRepository(container: container, portraitStore: PortraitStore())
        let balance = CurrencyBalance(copper: Int64.max - 10, silver: 1)
        let original = CharacterDocument(name: "Maximum", currencyBalance: balance)
        try await repository.save(original)
        let retained = try await repository.fetch(withID: original.id)
        XCTAssertEqual(retained.currencyBalance, balance)
    }

    func testOverflowCurrencyIsUnreadableAndRetained() async throws {
        for strategy in [JSONEncoder.DateEncodingStrategy.iso8601, .secondsSince1970] {
            let container = try ModelContainer(for: CharacterRecord.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = strategy
            let invalid = [CharacterDocument(name: "Product", currencyBalance: CurrencyBalance(platinum: Int64.max)),
                           CharacterDocument(name: "Sum", currencyBalance: CurrencyBalance(copper: Int64.max, silver: 1))]
            for document in invalid {
                container.mainContext.insert(try CharacterRecord(document: document, encoder: encoder))
            }
            try container.mainContext.save()
            let repository = SwiftDataCharacterRepository(container: container, portraitStore: PortraitStore())
            let result = try await repository.fetchCollection()
            XCTAssertTrue(result.characters.isEmpty)
            XCTAssertEqual(Set(result.unreadableRecords.map(\.id)), Set(invalid.map(\.id)))
            for unreadable in result.unreadableRecords {
                guard case .corrupted(_, let cause) = unreadable.error as? CharacterStoreError else {
                    return XCTFail("Expected corrupt overflow record")
                }
                XCTAssertEqual(cause as? ConvertCurrencyUseCase.ConversionError, .amountTooLarge)
            }
            XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<CharacterRecord>()), invalid.count)
        }
    }

    // UT-PR115-NEGATIVE-COINS: decoding enforces the save invariant for every denomination and date format.
    func testNegativeCurrencyIsUnreadableAndRetained() async throws {
        let invalidBalances = [CurrencyBalance(copper: -1), CurrencyBalance(silver: -1),
                               CurrencyBalance(electrum: -1), CurrencyBalance(gold: -1),
                               CurrencyBalance(platinum: -1)]
        for strategy in [JSONEncoder.DateEncodingStrategy.iso8601, .secondsSince1970] {
            let container = try ModelContainer(for: CharacterRecord.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let repository = SwiftDataCharacterRepository(container: container,
                portraitStore: PortraitStore())
            let valid = CharacterDocument(name: "Zero balance", currencyBalance: .zero)
            try await repository.save(valid)
            var invalidIDs: Set<UUID> = []
            for balance in invalidBalances {
                let invalid = CharacterDocument(name: "Negative balance", currencyBalance: balance)
                invalidIDs.insert(invalid.id)
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = strategy
                container.mainContext.insert(try CharacterRecord(document: invalid, encoder: encoder))
            }
            try container.mainContext.save()
            let collection = try await repository.fetchCollection()
            XCTAssertEqual(collection.characters.map(\.id), [valid.id])
            XCTAssertEqual(Set(collection.unreadableRecords.map(\.id)), invalidIDs)
            for unreadable in collection.unreadableRecords {
                guard case .corrupted(let id, let cause) = unreadable.error as? CharacterStoreError else {
                    return XCTFail("Expected corrupted currency metadata")
                }
                XCTAssertEqual(id, unreadable.id)
                XCTAssertEqual(cause as? ConvertCurrencyUseCase.ConversionError, .invalidCoinCount)
            }
            XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<CharacterRecord>()), 6)
            do {
                _ = try await repository.fetch(withID: XCTUnwrap(invalidIDs.first))
                XCTFail("Negative currency must not be readable by ID")
            } catch {
                XCTAssertTrue(error is CharacterStoreError)
            }
        }
    }

    // UT-PR115-RULESET: unsupported rulesets stay visible without being interpreted or deleted.
    func testUnsupportedRulesetRemainsUnreadableForBothDateFormats() async throws {
        for strategy in [JSONEncoder.DateEncodingStrategy.iso8601, .secondsSince1970] {
            let container = try ModelContainer(for: CharacterRecord.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let repository = SwiftDataCharacterRepository(container: container,
                portraitStore: PortraitStore())
            let valid = CharacterDocument(name: "Supported")
            try await repository.save(valid)
            let foreign = CharacterDocument(rulesetID: "other-ruleset", name: "Other rules")
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = strategy
            let record = try CharacterRecord(document: foreign, encoder: encoder)
            container.mainContext.insert(record)
            try container.mainContext.save()

            let collection = try await repository.fetchCollection()
            XCTAssertEqual(collection.characters.map(\.id), [valid.id])
            XCTAssertEqual(collection.unreadableRecords.map(\.id), [foreign.id])
            XCTAssertEqual(collection.unreadableRecords.first?.name, foreign.name)
            let failure = try XCTUnwrap(collection.unreadableRecords.first?.error as? CharacterStoreError)
            guard case .unsupportedRuleset(let ruleset) = failure else {
                return XCTFail("Expected unsupported ruleset metadata")
            }
            XCTAssertEqual(ruleset, foreign.rulesetID)
            XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<CharacterRecord>()), 2)
            do {
                _ = try await repository.fetch(withID: foreign.id)
                XCTFail("Unsupported ruleset must not be readable by ID")
            } catch {
                guard case .unsupportedRuleset(let ruleset) = error as? CharacterStoreError else {
                    return XCTFail("Expected unsupported ruleset on direct fetch")
                }
                XCTAssertEqual(ruleset, foreign.rulesetID)
            }
        }
    }

    func testMixedCollectionKeepsCorruptRecordsVisibleUntilExplicitDeletion() async throws {
        let container = try ModelContainer(for: CharacterRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let repository = SwiftDataCharacterRepository(container: container, portraitStore: PortraitStore())
        let valid = CharacterDocument(name: "Readable")
        try await repository.save(valid)
        let corrupt = try CharacterRecord(document: CharacterDocument(name: "Unreadable"))
        corrupt.payload = Data("invalid JSON".utf8)
        context.insert(corrupt)
        try context.save()

        let collection = try await repository.fetchCollection()
        XCTAssertEqual(collection.characters.map(\.id), [valid.id])
        XCTAssertEqual(collection.unreadableRecords.map(\.id), [corrupt.id])
        XCTAssertEqual(collection.unreadableRecords.first?.name, "Unreadable")
        let failure = try XCTUnwrap(collection.unreadableRecords.first?.error as? CharacterStoreError)
        guard case .corrupted(let reportedID, _) = failure else {
            return XCTFail("Expected corruption metadata")
        }
        XCTAssertEqual(reportedID, corrupt.id)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CharacterRecord>()), 2)

        try await repository.delete(withID: corrupt.id)
        let recovered = try await repository.fetchCollection()
        XCTAssertEqual(recovered.characters.map(\.id), [valid.id])
        XCTAssertTrue(recovered.unreadableRecords.isEmpty)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CharacterRecord>()), 1)
    }

    func testUnsupportedSchemaRemainsVisibleWithOriginalFailure() async throws {
        let container = try ModelContainer(for: CharacterRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        var future = CharacterDocument(name: "Future")
        future.schemaVersion = CharacterDocument.currentSchemaVersion + 1
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let record = try CharacterRecord(document: future, encoder: encoder)
        container.mainContext.insert(record)
        try container.mainContext.save()
        let repository = SwiftDataCharacterRepository(container: container,
                                                       portraitStore: PortraitStore())
        let collection = try await repository.fetchCollection()
        XCTAssertTrue(collection.characters.isEmpty)
        let failure = try XCTUnwrap(collection.unreadableRecords.first?.error as? CharacterStoreError)
        guard case .unsupportedSchema(let version) = failure else {
            return XCTFail("Expected unsupported schema metadata")
        }
        XCTAssertEqual(version, future.schemaVersion)
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<CharacterRecord>()), 1)
    }
}
