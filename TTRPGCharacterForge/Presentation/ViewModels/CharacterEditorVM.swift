//
//  CharacterEditorVM.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

/// Manages editable character state and creation-step validation.
@MainActor
final class CharacterEditorVM: ObservableObject {
    private let createCharacterUseCase: CreateCharacterUseCase
    private let updateAbilityScoreUseCase: UpdateAbilityScoreUseCase
    private let computeDerivedStatsUseCase: ComputeDerivedStatsUseCase
    private let saveCharacterUseCase: SaveCharacterUseCase
    private let catalog: RulesCatalog
    private let portraitStore: PortraitStore
    private let pdfExporter: ExportCharacterPdfUseCase
    private let tokenExporter: GenerateVTTTokenUseCase

    @Published var character: CharacterDocument {
        didSet { if !isApplyingSavedSnapshot { autosave() } }
    }
    @Published var derivedStats: DerivedCharacterStats?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var exportedPDF: URL?
    @Published var exportedToken: URL?
    private var autosaveTask: Task<Void, Error>?
    private var saveTail: Task<Void, Error>?
    private var isApplyingSavedSnapshot = false

    init(
        createCharacterUseCase: CreateCharacterUseCase,
        updateAbilityScoreUseCase: UpdateAbilityScoreUseCase,
        computeDerivedStatsUseCase: ComputeDerivedStatsUseCase,
        saveCharacterUseCase: SaveCharacterUseCase,
        catalog: RulesCatalog,
        character: CharacterDocument? = nil,
        portraitStore: PortraitStore,
        pdfExporter: ExportCharacterPdfUseCase = ExportCharacterPdfUseCase(exporter: CharacterSheetPDFExporter()),
        tokenExporter: GenerateVTTTokenUseCase = GenerateVTTTokenUseCase(renderer: UIKitTokenRenderer())
    ) {
        self.createCharacterUseCase = createCharacterUseCase
        self.updateAbilityScoreUseCase = updateAbilityScoreUseCase
        self.computeDerivedStatsUseCase = computeDerivedStatsUseCase
        self.saveCharacterUseCase = saveCharacterUseCase
        self.catalog = catalog
        self.character = character ?? createCharacterUseCase.makeDraft()
        self.portraitStore = portraitStore
        self.tokenExporter = tokenExporter
        self.pdfExporter = pdfExporter
        refreshDerivedStats()
    }

    var races: [RaceRule] { catalog.races }
    var classes: [ClassRule] { catalog.classes }
    var backgrounds: [BackgroundRule] { catalog.backgrounds }
    var skills: [SkillRule] { catalog.skills }
    var equipment: [EquipmentRule] { catalog.equipment }
    var spells: [SpellRule] {
        guard let classID = character.classID else { return [] }
        return catalog.spells.filter { $0.level <= 1 && $0.classIDs.contains(classID) }
    }
    var steps: [CharacterCreationStep] { CharacterCreationStep.allCases }

    func setAbility(_ ability: AbilityID, score: Int, method: AbilityAssignmentMethod) {
        do {
            try updateAbilityScoreUseCase.execute(
                character: &character,
                ability: ability,
                score: score,
                method: method
            )
            errorMessage = nil
            refreshDerivedStats()
            autosave()
        } catch { errorMessage = error.localizedDescription }
    }

    func advance() {
        guard let next = CharacterCreationStep(rawValue: character.currentStep.rawValue + 1) else { return }
        character.currentStep = next
        autosave()
    }

    func goBack() {
        guard let previous = CharacterCreationStep(rawValue: character.currentStep.rawValue - 1) else { return }
        character.currentStep = previous
        autosave()
    }

    func complete() async -> Bool {
        guard !isLoading else { return false }
        isLoading = true
        defer { isLoading = false }
        do {
            var completed = character
            // Validation must not cancel a pending draft save.
            try createCharacterUseCase.validateForCompletion(completed, catalog: catalog)
            completed.state = .completed
            autosaveTask?.cancel()
            try await persist(completed)
            var latest = character
            latest.state = .completed
            applySavedSnapshot(latest)
            if latest != completed { autosave() }
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func flushAutosave() async -> Bool {
        guard !isLoading else { return false }
        isLoading = true
        defer { isLoading = false }
        autosaveTask?.cancel()
        do {
            var snapshot = character
            try await persist(snapshot)
            while character != snapshot {
                autosaveTask?.cancel()
                snapshot = character
                try await persist(snapshot)
            }
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func autosave() {
        isApplyingSavedSnapshot = true
        character.updatedAt = Date()
        isApplyingSavedSnapshot = false
        refreshDerivedStats()
        autosaveTask?.cancel()
        let snapshot = character
        let saver = saveCharacterUseCase
        let previous = saveTail
        let task = Task { [weak self] in
            do {
                // Every queued task waits, including cancelled tasks, so the chain
                // cannot bypass an earlier repository write still in flight.
                _ = try? await previous?.value
                try await Task.sleep(for: .milliseconds(100))
                try Task.checkCancellation()
                try await saver.saveCharacter(snapshot)
            } catch {
                if !(error is CancellationError) { self?.errorMessage = error.localizedDescription }
                throw error
            }
        }
        saveTail = task
        autosaveTask = task
    }

    private func persist(_ snapshot: CharacterDocument) async throws {
        let previous = saveTail
        let saver = saveCharacterUseCase
        let task = Task {
            _ = try? await previous?.value
            try await saver.saveCharacter(snapshot)
        }
        saveTail = task
        try await task.value
    }

    private func applySavedSnapshot(_ snapshot: CharacterDocument) {
        isApplyingSavedSnapshot = true
        character = snapshot
        isApplyingSavedSnapshot = false
        refreshDerivedStats()
    }

    func toggleSkill(_ id: String) {
        guard !grantedSkillIDs.contains(id) else { return }
        Self.toggle(id, in: &character.selectedSkillIDs)
        autosave()
    }

    func toggleEquipment(_ id: String) {
        Self.toggle(id, in: &character.selectedEquipmentIDs)
        if !character.selectedEquipmentIDs.isEmpty {
            character.startingWealthGP = nil
            character.currencyBalance = nil
        }
        autosave()
    }

    func saveCurrencyBalance(_ balance: CurrencyBalance) async throws {
        guard !isLoading else { throw CancellationError() }
        isLoading = true
        defer { isLoading = false }
        guard [balance.copper, balance.silver, balance.electrum, balance.gold, balance.platinum]
            .allSatisfy({ $0 >= 0 }) else {
            throw ConvertCurrencyUseCase.ConversionError.invalidCoinCount
        }
        autosaveTask?.cancel()
        var updatedCharacter = character
        updatedCharacter.currencyBalance = balance
        updatedCharacter.startingWealthGP = nil
        updatedCharacter.updatedAt = Date()
        try await persist(updatedCharacter)
        var latest = character
        latest.currencyBalance = balance
        latest.startingWealthGP = nil
        applySavedSnapshot(latest)
        if latest != updatedCharacter { autosave() }
        errorMessage = nil
    }

    func toggleSpell(_ id: String) {
        Self.toggle(id, in: &character.selectedSpellIDs)
        autosave()
    }

    func importPortrait(_ data: Data) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let previousPortrait = character.portrait
            let replacement = try portraitStore.save(data, for: character.id)
            var updated = character
            updated.portrait = replacement
            autosaveTask?.cancel()
            try await persistPortrait(updated, replacement: replacement)
            var latest = character
            latest.portrait = replacement
            applySavedSnapshot(latest)
            if latest != updated { autosave() }
            if let previousPortrait, previousPortrait != replacement {
                try? portraitStore.delete(previousPortrait)
            }
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    private func persistPortrait(_ updated: CharacterDocument, replacement: PortraitReference) async throws {
        do {
            try await persist(updated)
        } catch {
            try? portraitStore.delete(replacement)
            throw error
        }
    }

    func prepareExports() {
        do {
            exportedPDF = try pdfExporter.execute(character: character, catalog: catalog)
            if let portrait = character.portrait {
                exportedToken = try tokenExporter.execute(
                    imageData: Data(contentsOf: portraitStore.url(for: portrait)),
                    filename: character.name,
                    crop: portrait.crop
                )
            }
        } catch { errorMessage = error.localizedDescription }
    }

    private static func toggle(_ id: String, in values: inout [String]) {
        if let index = values.firstIndex(of: id) { values.remove(at: index) } else { values.append(id) }
    }

    private func refreshDerivedStats() {
        derivedStats = try? computeDerivedStatsUseCase.execute(character: character, catalog: catalog)
    }
}


// Catalog grant reconciliation is shared by the editor controls.
extension CharacterEditorVM {
    var languages: [NamedRule] { catalog.languages }
    var grantedSkillIDs: Set<String> {
        Set(catalog.background(id: character.backgroundID)?.grantedSkillIDs ?? [])
    }
    var grantedLanguageIDs: Set<String> {
        Set(catalog.race(id: character.raceID)?.grantedLanguageIDs ?? [])
            .union(catalog.background(id: character.backgroundID)?.grantedLanguageIDs ?? [])
    }
    var additionalLanguageChoiceCount: Int {
        (catalog.race(id: character.raceID)?.additionalLanguageChoices ?? 0)
            + (catalog.background(id: character.backgroundID)?.additionalLanguageChoices ?? 0)
    }

    func reconcileClassSelection() {
        character.archetypeID = nil
        let available = Set(catalog.characterClass(id: character.classID)?.availableSkillIDs ?? [])
        character.selectedSkillIDs = Array(Set(character.selectedSkillIDs)
            .intersection(available).union(grantedSkillIDs)).sorted()
        let availableSpells = Set(spells.map(\.id))
        character.selectedSpellIDs.removeAll { !availableSpells.contains($0) }
    }

    func reconcileBackgroundSelection(previousID: String?) {
        let previous = catalog.background(id: previousID)
        character.selectedSkillIDs.removeAll { previous?.grantedSkillIDs.contains($0) == true }
        character.selectedLanguageIDs.removeAll { previous?.grantedLanguageIDs.contains($0) == true }
        character.selectedEquipmentIDs.removeAll { previous?.grantedEquipmentIDs.contains($0) == true }
        let background = catalog.background(id: character.backgroundID)
        character.selectedSkillIDs = Array(Set(character.selectedSkillIDs).union(grantedSkillIDs)).sorted()
        character.selectedLanguageIDs = Array(Set(character.selectedLanguageIDs).union(grantedLanguageIDs)).sorted()
        character.selectedEquipmentIDs = Array(Set(character.selectedEquipmentIDs)
            .union(background?.grantedEquipmentIDs ?? [])).sorted()
    }

    func applyRaceBonuses(previousID: String? = nil) {
        let previousLanguages = catalog.race(id: previousID)?.grantedLanguageIDs ?? []
        character.selectedLanguageIDs.removeAll { previousLanguages.contains($0) }
        character.selectedLanguageIDs = Array(Set(character.selectedLanguageIDs).union(grantedLanguageIDs)).sorted()
        character.racialAbilityBonuses = catalog.race(id: character.raceID)?.abilityBonuses ?? .zero
        refreshDerivedStats()
        autosave()
    }

    func toggleLanguage(_ id: String) {
        guard !grantedLanguageIDs.contains(id), catalog.languages.contains(where: { $0.id == id }) else { return }
        Self.toggle(id, in: &character.selectedLanguageIDs)
    }
}
