//
//  CharacterListViewModel.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

@MainActor
/// Loads and manages the collection of persisted characters.
final class CharacterListViewModel: ObservableObject {
    private let loadCharactersUseCase: LoadCharactersUseCase
    private let saveCharacterUseCase: SaveCharacterUseCase
    private var loadGeneration = UUID()

    @Published var characters: [CharacterDocument] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    init(
        loadCharactersUseCase: LoadCharactersUseCase,
        saveCharacterUseCase: SaveCharacterUseCase
    ) {
        self.loadCharactersUseCase = loadCharactersUseCase
        self.saveCharacterUseCase = saveCharacterUseCase
    }

    func loadCharacters() async {
        let generation = UUID()
        loadGeneration = generation
        isLoading = true
        errorMessage = nil
        do {
            let loaded = try await loadCharactersUseCase.getAllCharacters()
            guard generation == loadGeneration else { return }
            characters = loaded
        } catch is CancellationError {
        } catch {
            guard generation == loadGeneration else { return }
            errorMessage = String(format: NSLocalizedString("characters_load_error", comment: ""), error.localizedDescription)
        }
        if generation == loadGeneration { isLoading = false }
    }

    func save(_ character: CharacterDocument) async throws {
        try await saveCharacterUseCase.saveCharacter(character)
        await loadCharacters()
    }

    func duplicate(_ character: CharacterDocument) {
        Task {
            do {
                _ = try await loadCharactersUseCase.duplicate(character)
                await loadCharacters()
            } catch { errorMessage = error.localizedDescription }
        }
    }

    func delete(_ character: CharacterDocument) {
        Task {
            do {
                try await loadCharactersUseCase.delete(withID: character.id)
                await loadCharacters()
            } catch { errorMessage = error.localizedDescription }
        }
    }
}
