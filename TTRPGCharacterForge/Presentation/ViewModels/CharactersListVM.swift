//
//  CharacterListViewModel.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

/// Supplies legacy character data to the original character-list interface.
final class CharacterListViewModel: ObservableObject {
    private let loadCharactersUseCase: LoadCharactersUseCase
    private let saveCharacterUseCase: SaveCharacterUseCase
    
    init(
        loadCharactersUseCase: LoadCharactersUseCase,
        saveCharacterUseCase: SaveCharacterUseCase
    ) {
        self.loadCharactersUseCase = loadCharactersUseCase
        self.saveCharacterUseCase = saveCharacterUseCase
    }
}
