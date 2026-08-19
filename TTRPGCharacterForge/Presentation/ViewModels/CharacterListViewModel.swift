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
    
    func loadCharacters() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                characters = try await loadCharactersUseCase.getAllCharacters()
            } catch {
                errorMessage = String(
                    format: NSLocalizedString("characters_load_error", comment: ""),
                    error.localizedDescription
                )
            }
            isLoading = false
        }
    }

    func save(_ character: CharacterDocument) async throws {
        try await saveCharacterUseCase.saveCharacter(character)
        loadCharacters()
    }

    func duplicate(_ character: CharacterDocument) {
        Task {
            do {
                _ = try await loadCharactersUseCase.duplicate(character)
                loadCharacters()
            } catch { errorMessage = error.localizedDescription }
        }
    }

    func delete(_ character: CharacterDocument) {
        Task {
            do {
                try await loadCharactersUseCase.delete(withID: character.id)
                loadCharacters()
            } catch { errorMessage = error.localizedDescription }
        }
    }
}
