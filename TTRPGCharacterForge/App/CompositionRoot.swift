//
//  CompositionRoot.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation
import SwiftData

/// Responsible for setting up all dependencies and wiring up the application
@MainActor
final class CompositionRoot {
    let modelContainer: ModelContainer
    let rulesRepository: RulesRepository
    let characterRepository: CharacterRepository
    let portraitStore: PortraitStore

    init(inMemory: Bool = false) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        do {
            modelContainer = try ModelContainer(for: CharacterRecord.self, configurations: configuration)
        } catch {
            fatalError("Unable to create local character store: \(error)")
        }
        rulesRepository = BundledRulesRepository()
        portraitStore = PortraitStore()
        characterRepository = SwiftDataCharacterRepository(
            context: modelContainer.mainContext,
            portraitStore: portraitStore
        )
    }
    
    // MARK: - Coordinators
    
    lazy var spellsCoordinator: SpellsCoordinator = {
        SpellsCoordinator(spellUseCase: makeSpellUseCase())
    }()
    
    // MARK: - Private Factory Methods
    
    private func makeSpellUseCase() -> SpellUseCase {
        SpellUseCase(repository: makeSpellRepository())
    }
    
    private func makeSpellRepository() -> SpellRepository {
        LocalSpellRepository(rulesRepository: rulesRepository)
    }
    
    private func makeSpellCacheManager() -> SpellCacheManager {
        SpellCacheManager()
    }

    lazy var coordinator: Coordinator = {
        Coordinator(compositionRoot: self)
    }()

    func makeCharacterListViewModel() -> CharacterListViewModel {
        CharacterListViewModel(
            loadCharactersUseCase: LoadCharactersUseCase(repository: characterRepository),
            saveCharacterUseCase: SaveCharacterUseCase(repository: characterRepository)
        )
    }

    func makeCharacterEditorViewModel(character: CharacterDocument? = nil) throws -> CharacterEditorVM {
        CharacterEditorVM(
            createCharacterUseCase: CreateCharacterUseCase(),
            updateAbilityScoreUseCase: UpdateAbilityScoreUseCase(),
            computeDerivedStatsUseCase: ComputeDerivedStatsUseCase(),
            saveCharacterUseCase: SaveCharacterUseCase(repository: characterRepository),
            catalog: try rulesRepository.catalog(locale: .current),
            character: character,
            portraitStore: portraitStore
        )
    }
}
