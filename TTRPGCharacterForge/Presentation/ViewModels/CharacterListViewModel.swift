//
//  CharacterListViewModel.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

/// Loads and manages the collection of persisted characters.
@MainActor
final class CharacterListViewModel: ObservableObject {
    private let loadCharactersUseCase: LoadCharactersUseCase
    private let saveCharacterUseCase: SaveCharacterUseCase
    private var loadGeneration = UUID()

    @Published var unreadableRecords: [UnreadableCharacterRecord] = []
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
        defer { finishLoading(generation: generation) }
        do {
            let loaded = try await loadCharactersUseCase.getCharacterCollection()
            guard generation == loadGeneration else { return }
            characters = loaded.characters
            unreadableRecords = loaded.unreadableRecords
        } catch is CancellationError {
        } catch {
            guard generation == loadGeneration else { return }
            errorMessage = String(
                format: NSLocalizedString("characters_load_error", comment: ""),
                error.localizedDescription
            )
        }
    }

    private func finishLoading(generation: UUID) {
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

    func delete(_ character: CharacterDocument) { delete(withID: character.id) }

    func delete(withID id: UUID) {
        Task {
            do {
                try await loadCharactersUseCase.delete(withID: id)
                await loadCharacters()
            } catch { errorMessage = error.localizedDescription }
        }
    }
}
