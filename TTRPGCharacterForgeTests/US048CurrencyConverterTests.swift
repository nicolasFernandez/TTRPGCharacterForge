import XCTest
@testable import TTRPGCharacterForge

final class US048CurrencyConverterTests: XCTestCase {
    private let converter = ConvertCurrencyUseCase()

    // UT-001: AC-002, AC-003 / SC-001
    func testUT001_normalizesMixedBalanceExactly() throws {
        let result = try converter.execute(.init(
            copper: "105", silver: "11", electrum: "3", gold: "12", platinum: "2"
        ))

        XCTAssertEqual(result.totalCopper, 3_585)
        XCTAssertEqual(
            result.balance,
            CurrencyBalance(copper: 5, silver: 3, electrum: 1, gold: 5, platinum: 3)
        )
    }

    // UT-002: AC-002, AC-003 / SC-002
    func testUT002_convertsEveryDenominationToCanonicalBalance() throws {
        let rows: [(ConvertCurrencyUseCase.Input, Int64, CurrencyBalance)] = [
            (.init(copper: "10", silver: "", electrum: "", gold: "", platinum: ""), 10,
             .init(silver: 1)),
            (.init(copper: "", silver: "10", electrum: "", gold: "", platinum: ""), 100,
             .init(gold: 1)),
            (.init(copper: "", silver: "", electrum: "2", gold: "", platinum: ""), 100,
             .init(gold: 1)),
            (.init(copper: "", silver: "", electrum: "", gold: "10", platinum: ""), 1_000,
             .init(platinum: 1)),
            (.init(copper: "", silver: "", electrum: "", gold: "", platinum: "1"), 1_000,
             .init(platinum: 1))
        ]

        for (input, copper, balance) in rows {
            let result = try converter.execute(input)
            XCTAssertEqual(result.totalCopper, copper)
            XCTAssertEqual(result.balance, balance)
        }
    }

    // UT-003: AC-005 / SC-005
    func testUT003_formatsExactGPReferenceForEnglishAndSpanish() throws {
        let result = try converter.execute(.init(
            copper: "1", silver: "1", electrum: "1", gold: "1", platinum: "1"
        ))

        XCTAssertEqual(result.formattedTotalGP(locale: Locale(identifier: "en_US")), "11.61 gp")
        XCTAssertEqual(result.formattedTotalGP(locale: Locale(identifier: "es_ES")), "11,61 gp")
    }

    // UT-004: AC-006 / SC-006
    func testUT004_rejectsNegativeFractionalAndNonnumericCounts() {
        for input in [
            ConvertCurrencyUseCase.Input(copper: "-1", silver: "", electrum: "", gold: "", platinum: ""),
            .init(copper: "", silver: "", electrum: "", gold: "1.5", platinum: ""),
            .init(copper: "", silver: "", electrum: "", gold: "", platinum: "coins")
        ] {
            XCTAssertThrowsError(try converter.execute(input)) { error in
                XCTAssertEqual(error as? ConvertCurrencyUseCase.ConversionError, .invalidCoinCount)
            }
        }
    }

    // UT-005: AC-006 / SC-007
    func testUT005_rejectsOverflowWithoutReturningPartialResult() {
        let input = ConvertCurrencyUseCase.Input(
            copper: "", silver: "", electrum: "", gold: "", platinum: "9223372036854776"
        )

        XCTAssertThrowsError(try converter.execute(input)) { error in
            XCTAssertEqual(error as? ConvertCurrencyUseCase.ConversionError, .amountTooLarge)
        }
    }

    // UT-006: AC-004 / SC-004
    func testUT006_legacyDocumentWithoutCurrencyBalanceStillDecodes() throws {
        let legacyJSON = """
        {
          "id":"00000000-0000-0000-0000-000000000048",
          "schemaVersion":1,
          "rulesetID":"dnd5e-srd-2014",
          "state":"draft",
          "createdAt":0,
          "updatedAt":0,
          "currentStep":6,
          "name":"Legacy",
          "playerName":"",
          "baseAbilities":{"strength":0,"dexterity":0,"constitution":0,"intelligence":0,"wisdom":0,"charisma":0},
          "racialAbilityBonuses":{"strength":0,"dexterity":0,"constitution":0,"intelligence":0,"wisdom":0,"charisma":0},
          "selectedSkillIDs":[],
          "selectedLanguageIDs":[],
          "selectedEquipmentIDs":["leather-armor","dagger"],
          "startingWealthGP":37,
          "selectedSpellIDs":[],
          "personality":{"traits":"","ideals":"","bonds":"","flaws":""},
          "appearance":"",
          "notes":"",
          "overrides":{"savingThrows":{},"skills":{}}
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let character = try decoder.decode(CharacterDocument.self, from: Data(legacyJSON.utf8))
        XCTAssertNil(character.currencyBalance)
        XCTAssertEqual(character.startingWealthGP, 37)
        XCTAssertEqual(character.selectedEquipmentIDs, ["leather-armor", "dagger"])
    }

    // UT-007: AC-004, AC-007 / SC-003, SC-008
    @MainActor
    func testUT007_savePersistsBalanceAndDoesNotChangeEquipment() async throws {
        let repository = RecordingCharacterRepository()
        let original = CharacterDocument(
            name: "Currency QA",
            selectedEquipmentIDs: ["leather-armor", "dagger"],
            currencyBalance: .init(platinum: 1)
        )
        let viewModel = makeViewModel(character: original, repository: repository)
        let balance = CurrencyBalance(electrum: 1, gold: 2)

        try await viewModel.saveCurrencyBalance(balance)

        XCTAssertEqual(repository.saved?.currencyBalance, balance)
        XCTAssertEqual(repository.saved?.selectedEquipmentIDs, original.selectedEquipmentIDs)
        XCTAssertEqual(viewModel.character.currencyBalance, balance)
    }

    // UT-008: AC-006 / SC-006, SC-007
    @MainActor
    func testUT008_failedSaveLeavesEditorBalanceUnchanged() async {
        let repository = RecordingCharacterRepository(shouldFailSave: true)
        let originalBalance = CurrencyBalance(gold: 5)
        let original = CharacterDocument(currencyBalance: originalBalance)
        let viewModel = makeViewModel(character: original, repository: repository)

        do {
            try await viewModel.saveCurrencyBalance(.init(platinum: 2))
            XCTFail("Expected persistence to fail")
        } catch {
            XCTAssertEqual(viewModel.character.currencyBalance, originalBalance)
        }
    }

    @MainActor
    private func makeViewModel(
        character: CharacterDocument,
        repository: RecordingCharacterRepository
    ) -> CharacterEditorVM {
        CharacterEditorVM(
            createCharacterUseCase: CreateCharacterUseCase(),
            updateAbilityScoreUseCase: UpdateAbilityScoreUseCase(),
            computeDerivedStatsUseCase: ComputeDerivedStatsUseCase(),
            saveCharacterUseCase: SaveCharacterUseCase(repository: repository),
            catalog: RulesCatalog(
                schemaVersion: 1,
                rulesetID: CharacterDocument.rulesetID,
                locale: "en",
                races: [], classes: [], backgrounds: [], skills: [], languages: [], equipment: [], spells: []
            ),
            character: character,
            portraitStore: PortraitStore()
        )
    }
}

@MainActor
private final class RecordingCharacterRepository: CharacterRepository {
    enum TestError: Error { case saveFailed }

    private let shouldFailSave: Bool
    private(set) var saved: CharacterDocument?

    init(shouldFailSave: Bool = false) {
        self.shouldFailSave = shouldFailSave
    }

    func fetchAll() async throws -> [CharacterDocument] { saved.map { [$0] } ?? [] }
    func fetch(withID id: UUID) async throws -> CharacterDocument {
        guard let saved, saved.id == id else { throw CharacterStoreError.notFound(id) }
        return saved
    }
    func save(_ character: CharacterDocument) async throws {
        if shouldFailSave { throw TestError.saveFailed }
        saved = character
    }
    func duplicate(_ character: CharacterDocument) async throws -> CharacterDocument { character }
    func delete(withID id: UUID) async throws { saved = nil }
}
