//
//  CharacterEditorVM.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

@MainActor
/// Manages editable character state and creation-step validation.
final class CharacterEditorVM: ObservableObject {

    private let createCharacterUseCase: CreateCharacterUseCase
    private let updateAbilityScoreUseCase: UpdateAbilityScoreUseCase
    private let computeDerivedStatsUseCase: ComputeDerivedStatsUseCase
    private let saveCharacterUseCase: SaveCharacterUseCase
    private let catalog: RulesCatalog
    private let portraitStore: PortraitStore
    private let pdfExporter = ExportCharacterPdfUseCase()
    private let tokenExporter = GenerateVTTTokenUseCase()

    @Published var character: CharacterDocument
    @Published var derivedStats: DerivedCharacterStats?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var exportedPDF: URL?
    @Published var exportedToken: URL?
    
    init(
        createCharacterUseCase: CreateCharacterUseCase,
        updateAbilityScoreUseCase: UpdateAbilityScoreUseCase,
        computeDerivedStatsUseCase: ComputeDerivedStatsUseCase,
        saveCharacterUseCase: SaveCharacterUseCase,
        catalog: RulesCatalog,
        character: CharacterDocument? = nil,
        portraitStore: PortraitStore
    ) {
        self.createCharacterUseCase = createCharacterUseCase
        self.updateAbilityScoreUseCase = updateAbilityScoreUseCase
        self.computeDerivedStatsUseCase = computeDerivedStatsUseCase
        self.saveCharacterUseCase = saveCharacterUseCase
        self.catalog = catalog
        self.character = character ?? createCharacterUseCase.makeDraft()
        self.portraitStore = portraitStore
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
        do {
            try createCharacterUseCase.validateForCompletion(character, catalog: catalog)
            character.state = .completed
            try await saveCharacterUseCase.saveCharacter(character)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func autosave() {
        character.updatedAt = Date()
        refreshDerivedStats()
        Task {
            do { try await saveCharacterUseCase.saveCharacter(character) }
            catch { errorMessage = error.localizedDescription }
        }
    }

    func applyRaceBonuses() {
        character.racialAbilityBonuses = catalog.race(id: character.raceID)?.abilityBonuses ?? .zero
        refreshDerivedStats()
    }

    func toggleSkill(_ id: String) {
        Self.toggle(id, in: &character.selectedSkillIDs)
        autosave()
    }

    func toggleEquipment(_ id: String) {
        Self.toggle(id, in: &character.selectedEquipmentIDs)
        if !character.selectedEquipmentIDs.isEmpty { character.startingWealthGP = nil }
        autosave()
    }

    func toggleSpell(_ id: String) {
        Self.toggle(id, in: &character.selectedSpellIDs)
        autosave()
    }

    func importPortrait(_ data: Data) {
        do {
            if let existing = character.portrait { try? portraitStore.delete(existing) }
            character.portrait = try portraitStore.save(data, for: character.id)
            autosave()
        } catch { errorMessage = error.localizedDescription }
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
        if let index = values.firstIndex(of: id) { values.remove(at: index) }
        else { values.append(id) }
    }

    private func refreshDerivedStats() {
        derivedStats = try? computeDerivedStatsUseCase.execute(character: character, catalog: catalog)
    }
}
